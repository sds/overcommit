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

  describe '#post_fail_message' do
    subject { context.post_fail_message }

    it { should be_nil }
  end
end
