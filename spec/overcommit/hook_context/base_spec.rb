# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::HookContext::Base do
  let(:config) { double('config') }
  let(:args) { [] }
  let(:input) { double('input') }
  let(:context) { described_class.new(config, args, input) }

  describe '#hook_class_name' do
    subject { context.hook_class_name }

    it 'returns the short class name of the context' do
      subject.should == 'Base'
    end
  end

  describe '#input_lines' do
    subject { context.input_lines }

    before do
      input.stub(:read).and_return("line 1\nline 2\n")
    end

    it { should == ['line 1', 'line 2'] }
  end

  describe '#input_string' do
    let(:input_class) do
      Class.new do
        attr_reader :read_count

        def initialize(value)
          @value = value
          @read_count = 0
          @lock = Mutex.new
          @read_started = Queue.new
          @read_finished = Queue.new
        end

        def read
          @lock.synchronize do
            @read_count += 1
            raise 'input stream was read more than once' if @read_count > 1
          end

          @read_started << true
          @read_finished.pop
          @value
        end

        def wait_until_reading
          @read_started.pop
        end

        def finish_reading
          @read_finished << true
        end
      end
    end

    let(:input) { input_class.new("line 1\nline 2\n") }

    it 'shares one input stream read across concurrent callers' do
      first_reader = Thread.new { context.input_string }
      input.wait_until_reading

      second_reader = Thread.new { context.input_string }
      Thread.pass until second_reader.status == 'sleep'

      input.finish_reading
      results = [first_reader, second_reader].map(&:value)

      results.should == Array.new(2, "line 1\nline 2\n")
      input.read_count.should == 1
    end
  end

  describe '#post_fail_message' do
    subject { context.post_fail_message }

    it { should be_nil }
  end
end
