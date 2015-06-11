require 'spec_helper'

describe Overcommit::Hook::Base do
  let(:config) { double('config') }
  let(:context) { double('context') }
  let(:hook) { described_class.new(config, context) }

  describe '#run_and_transform' do
    let(:var_name) { 'OVERCOMMIT_TEST_HOOK_VAR' }
    let(:hook_config) { {} }

    before do
      config.stub(:for_hook).and_return(hook_config)
      hook.stub(:run) { ENV[var_name] == 'pass' ? :pass : :fail }
    end

    subject { hook.run_and_transform }

    context 'when no env configuration option is specified' do
      let(:hook_config) { {} }

      it 'does not modify the environment' do
        subject.first.should == :fail
      end
    end

    context 'when env configuration option is specified' do
      let(:hook_config) { { 'env' => { var_name => 'pass' } } }

      it 'modifies the environment' do
        subject.first.should == :pass
      end
    end
  end
end
