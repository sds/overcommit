# General spec matcher logic for checking hook status and output.
class HookMatcher
  def initialize(status, args)
    options = args.empty? ? {} : { message: args.first }
    @expected_status = status
    @expected_message = options[:message]
  end

  def matches?(check)
    result = [check.run].flatten
    if result.is_a?(Array) &&
       (result.first.is_a?(Overcommit::Hook::Message) || result.empty?)
      messages_match?(result)
    else
      actual_status, actual_message = result
      status_matches?(actual_status) && message_matches?(actual_message)
    end
  end

  def messages_match?(messages)
    case @expected_status
    when :fail
      messages.any? { |message| message.type == :error }
    when :warn
      messages.any? { |message| message.type == :warning }
    else
      messages.empty?
    end
  end

  def status_matches?(actual_status)
    @expected_status.nil? || actual_status == @expected_status
  end

  def message_matches?(actual_message)
    return true if @expected_message.nil?

    if @expected_message.is_a?(Regexp)
      actual_message =~ @expected_message
    else
      actual_message == @expected_message
    end
  end

  def failure_message(actual, error_message)
    actual_status, actual_message = [actual].flatten

    if status_matches?(actual_status)
      error_message <<
        " with message matching #{@expected_message.inspect}," \
        " but was #{actual_message.inspect}"
    end

    error_message
  end
end

# Can't use 'fail' as it is a reserved word.
RSpec::Matchers.define :fail_hook do |*args|
  check_matcher = HookMatcher.new(:fail, args)

  match do
    check_matcher.matches?(actual)
  end

  failure_message do
    check_matcher.failure_message(
      actual,
      'expected that the hook would fail'
    )
  end

  failure_message_when_negated do
    'expected that the hook would not fail'
  end

  description { 'fail' }
end

RSpec::Matchers.define :pass do |*args|
  check_matcher = HookMatcher.new(:pass, args)

  match do
    check_matcher.matches?(actual)
  end

  failure_message do
    check_matcher.failure_message(
      actual,
      'expected that the check would pass'
    )
  end

  failure_message_when_negated do
    'expected that the check would not pass'
  end

  description { 'pass the check' }
end

RSpec::Matchers.define :warn do |*args|
  check_matcher = HookMatcher.new(:warn, args)

  match do |check|
    check_matcher.matches?(check)
  end

  failure_message do
    check_matcher.failure_message(
      actual,
      'expected that the check would report a warning'
    )
  end

  failure_message_when_negated do
    'expected that the check would not report a warning'
  end

  description { 'report a warning' }
end
