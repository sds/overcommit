# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::HookSigner do
  describe '#signature_verified?' do
    let(:config) { double('config') }
    let(:context) { double('context') }

    let(:signer) do
      described_class.new('.git-hooks/pre_commit/some_path.rb', config, context)
    end

    let(:original_hook_config) { { 'enabled' => false } }
    let(:hook_config) { original_hook_config }
    let(:modified_hook_config) { hook_config }

    let(:original_hook_contents) { <<-RUBY }
      module Overcommit::Hook::PreCommit
        class SomeHook
          def run
            :pass
          end
        end
      end
    RUBY
    let(:hook_contents) { original_hook_contents }
    let(:modified_hook_contents) { hook_contents }

    subject { signer.signature_verified? }

    around do |example|
      repo do
        example.run
      end
    end

    before do
      Overcommit::GitRepo.stub(:tracked?).and_return(true)
      context.stub(:hook_class_name).and_return('PreCommit')
      context.stub(:hook_type_name).and_return('pre-commit')
      config.stub(:verify_signatures?).and_return(true)
      config.stub(:for_hook).and_return(hook_config)
      config.stub(:plugin_directory).and_return(Dir.pwd)
      signer.stub(:hook_contents).and_return(hook_contents)

      signer.update_signature!

      config.stub(:for_hook).and_return(modified_hook_config)
      signer.stub(:hook_contents).and_return(modified_hook_contents)
    end

    shared_context 'hook code has changed' do
      let(:modified_hook_contents) { <<-RUBY }
        module Overcommit::Hook::PreCommit
          class SomeHook
            def run
              :fail # This line changed
            end
          end
        end
      RUBY
    end

    shared_context 'hook code has changed back' do
      include_context 'hook code has changed'
      before do
        signer.update_signature!
        config.stub(:for_hook).and_return(modified_hook_config)
        signer.stub(:hook_contents).and_return(original_hook_contents)
      end
    end

    shared_context 'hook config has changed' do
      let(:modified_hook_config) { { 'enabled' => true } }
    end

    shared_context 'hook config has changed back' do
      include_context 'hook config has changed'
      before do
        signer.update_signature!
        config.stub(:for_hook).and_return(original_hook_config)
        signer.stub(:hook_contents).and_return(modified_hook_contents)
      end
    end

    shared_examples 'signature has been verified' do
      it { should == true }
    end

    shared_examples 'signature has not been verified' do
      it { should == false }
    end

    context 'when the hook code and config are the same' do
      include_examples 'signature has been verified'

      context 'and the user has specified they wish to skip the hook' do
        let(:modified_hook_config) { hook_config.merge('skip' => true) }

        include_examples 'signature has been verified'
      end
    end

    context 'when the hook code has changed' do
      include_context 'hook code has changed'

      include_examples 'signature has not been verified'
    end

    context 'when the hook code has changed back to a previously verified signature' do
      include_context 'hook code has changed back'

      include_examples 'signature has been verified'
    end

    context 'when the hook config has changed' do
      include_context 'hook config has changed'

      include_examples 'signature has not been verified'
    end

    context 'when the hook config has changed back' do
      include_context 'hook config has changed back'

      include_examples 'signature has been verified'
    end
  end
end
