class CheckMatcher
  def initialize(options)
    @expected_status = options[:status]
    @expected_message = options[:message]
  end

  def matches?(check)
    actual_status, actual_message = [check.run_check].flatten
    status_matches?(actual_status) && message_matches?(actual_message)
  end

  def status_matches?(actual_status)
    @expected_status.nil? || actual_status == @expected_status
  end

  def message_matches?(actual_message)
    return true if @expected_message.nil?

    @expected_message.is_a?(Regexp) ?
      actual_message =~ @expected_message :
      actual_message == @expected_message
  end

  def failure_message(actual, error_message)
    actual_status, actual_message = [actual].flatten

    if status_matches?(actual_status)
      error_message <<
        " with message matching #{@expected_message.inspect}," <<
        " but was #{actual_message.inspect}"
    end

    error_message
  end
end

# Can't call this `fail` since that is a reserved word in Ruby
RSpec::Matchers.define :fail_check do |message|
  check_matcher = CheckMatcher.new(status: :bad, message: message)

  match do |check|
    check_matcher.matches?(actual)
  end

  failure_message_for_should do
    check_matcher.failure_message(
      check.run_check,
      'expected that the check would fail',
    )
  end

  failure_message_for_should_not do
    'expected that the check would not fail'
  end

  description { 'fail the check' }
end

RSpec::Matchers.define :stop do |message|
  check_matcher = CheckMatcher.new(status: :stop, message: message)

  match do |check|
    check_matcher.matches?(actual)
  end

  failure_message_for_should do
    check_matcher.failure_message(
      check.run_check,
      'expected that the check would fail and halt further checking',
    )
  end

  failure_message_for_should_not do
    'expected that the check would not fail with a stopping error'
  end

  description { 'fail and halt further checking' }
end

RSpec::Matchers.define :pass do |message|
  check_matcher = CheckMatcher.new(status: :good, message: message)

  match do |check|
    check_matcher.matches?(actual)
  end

  failure_message_for_should do
    check_matcher.failure_message(
      check.run_check,
      'expected that the check would pass',
    )
  end

  failure_message_for_should_not do
    'expected that the check would not pass'
  end

  description { 'pass the check' }
end

RSpec::Matchers.define :warn do |message|
  check_matcher = CheckMatcher.new(status: :warn, message: message)

  match do |check|
    check_matcher.matches?(check)
  end

  failure_message_for_should do |check|
    check_matcher.failure_message(
      check.run_check,
      'expected that the check would report a warning',
    )
  end

  failure_message_for_should_not do
    'expected that the check would not report a warning'
  end

  description { 'report a warning' }
end
