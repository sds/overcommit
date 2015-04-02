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
end
