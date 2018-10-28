# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::HookSigner do
  describe '#signature_changed?' do
    let(:config) { double('config') }
    let(:context) { double('context') }

    let(:signer) do
      described_class.new('.git-hooks/pre_commit/some_path.rb', config, context)
    end

    let(:hook_config) { { 'enabled' => false } }
    let(:modified_hook_config) { hook_config }

    let(:hook_contents) { <<-RUBY }
      module Overcommit::Hook::PreCommit
        class SomeHook
          def run
            :pass
          end
        end
      end
    RUBY

    let(:modified_hook_contents) { hook_contents }

    subject { signer.signature_changed? }

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

    context 'when the hook code and config are the same' do
      it { should == false }

      context 'and the user has specified they wish to skip the hook' do
        let(:modified_hook_config) { hook_config.merge('skip' => true) }

        it { should == false }
      end
    end

    context 'when the hook code has changed' do
      let(:modified_hook_contents) { <<-RUBY }
        module Overcommit::Hook::PreCommit
          class SomeHook
            def run
              :fail # This line changed
            end
          end
        end
      RUBY

      it { should == true }
    end

    context 'when the hook config has changed' do
      let(:modified_hook_config) { { 'enabled' => true } }

      it { should == true }
    end
  end
end
