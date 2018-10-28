# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PostCheckout::Base do
  let(:config) { double('config') }
  let(:context) { double('context') }
  let(:hook) { described_class.new(config, context) }

  let(:hook_config) { {} }

  before do
    config.stub(:for_hook).and_return(hook_config)
  end

  describe '#skip_file_checkout?' do
    subject { hook.skip_file_checkout? }

    context 'when skip_file_checkout is not set' do
      it { should == true }
    end

    context 'when skip_file_checkout is set to false' do
      let(:hook_config) { { 'skip_file_checkout' => false } }

      it { should == false }
    end

    context 'when skip_file_checkout is set to true' do
      let(:hook_config) { { 'skip_file_checkout' => true } }

      it { should == true }
    end
  end

  describe '#enabled?' do
    subject { hook.enabled? }

    shared_examples 'hook enabled' do |enabled, skip_file_checkout, file_checkout, expected|
      context "when enabled is set to #{enabled}" do
        context "when skip_file_checkout is set to #{skip_file_checkout}" do
          context "when file_checkout? is #{file_checkout}" do
            let(:hook_config) do
              { 'enabled' => enabled, 'skip_file_checkout' => skip_file_checkout }
            end

            before do
              context.stub(:file_checkout?).and_return(file_checkout)
            end

            it { should == expected }
          end
        end
      end
    end

    include_examples 'hook enabled', true,  true,  true,  false
    include_examples 'hook enabled', true,  true,  false, true
    include_examples 'hook enabled', true,  false, true,  true
    include_examples 'hook enabled', true,  false, false, true
    include_examples 'hook enabled', false, true,  true,  false
    include_examples 'hook enabled', false, true,  false, false
    include_examples 'hook enabled', false, false, true,  false
    include_examples 'hook enabled', false, false, false, false
  end
end
