require 'spec_helper'

describe Overcommit::HookContext::Base do
  let(:config) { double('config') }
  let(:args) { [] }
  let(:context) { described_class.new(config, args) }

  describe '#hook_class_name' do
    subject { context.hook_class_name }

    it 'returns the short class name of the context' do
      subject.should == 'Base'
    end
  end
end
