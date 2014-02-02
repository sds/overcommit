class CheckMatcher
  def initialize(options)
    @expected_status = options[:status]
    @expected_message = options[:message]
  end

  def matches?(check)
    actual_status, actual_message = [check.run].flatten
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

# Can't use 'fail' as it is a reserved word.
RSpec::Matchers.define :fail_check  do |message|
  check_matcher = CheckMatcher.new(:status => :bad, :message => message)

  match do |check|
    check_matcher.matches?(actual)
  end

  failure_message_for_should do |check|
    check_matcher.failure_message(
      actual,
      'expected that the hook would fail'
    )
  end

  failure_message_for_should_not do
    'expected that the hook would not fail'
  end

  description { 'fail' }
end

RSpec::Matchers.define :pass do |message|
  check_matcher = CheckMatcher.new(:status => :good, :message => message)

  match do |check|
    check_matcher.matches?(actual)
  end

  failure_message_for_should do |check|
    check_matcher.failure_message(
      actual,
      'expected that the check would pass'
    )
  end

  failure_message_for_should_not do
    'expected that the check would not pass'
  end

  description { 'pass the check' }
end

RSpec::Matchers.define :warn do |message|
  check_matcher = CheckMatcher.new(:status => :warn, :message => message)

  match do |check|
    check_matcher.matches?(check)
  end

  failure_message_for_should do |check|
    check_matcher.failure_message(
      actual,
      'expected that the check would report a warning'
    )
  end

  failure_message_for_should_not do
    'expected that the check would not report a warning'
  end

  description { 'report a warning' }
end
