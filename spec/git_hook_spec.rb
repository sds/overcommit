require 'spec_helper'

describe Overcommit::GitHook::BaseHook do
  describe '#initialize' do
    context 'with no plugins' do
      it 'initializes' do
        expect { subject }.to_not raise_error
      end
    end
  end

  describe '#run' do
    context 'with no hooks registered' do
      before do
        subject.stub(:registered_checks).and_return([])
      end

      it 'does not raise' do
        expect { subject.run }.to_not raise_error
      end
    end

    context 'with a hook registered' do
      class DummyHook < Overcommit::GitHook::HookSpecificCheck
      end

      let!(:hook) { DummyHook.new }

      before do
        subject.stub(:registered_checks).and_return([DummyHook])
        DummyHook.stub(:new).and_return hook
      end

      context 'when not skipping' do
        before do
          hook.stub(:skip?).and_return false
        end

        it 'runs the hook' do
          hook.should_receive(:run_check)
          subject.run
        end
      end

      context 'when the hook wants to `skip?`' do
        before do
          hook.stub(:skip?).and_return true
        end

        it 'does not run the check' do
          hook.should_not_receive(:run_check)
          subject.run
        end
      end
    end

    context 'with a required hook registered' do
      class RequiredHook < Overcommit::GitHook::HookSpecificCheck
        include Overcommit::GitHook::HookRegistry
        required!
      end

      # This one will be skipped via the environment variable
      class OptionalHook < Overcommit::GitHook::HookSpecificCheck
        include Overcommit::GitHook::HookRegistry
      end

      let!(:required_hook) { RequiredHook.new }
      let!(:optional_hook) { OptionalHook.new }

      before do
        Overcommit::GitHook::HookRegistry.stub(:checks).
          and_return([RequiredHook, OptionalHook])
        subject.stub(:skip_checks).and_return(['all'])
        RequiredHook.stub(:new).and_return(required_hook)
        OptionalHook.stub(:new).and_return(optional_hook)
      end

      it 'runs the required hook' do
        required_hook.should_receive(:run_check)
        subject.run
      end

      it 'skips the non-required hook' do
        optional_hook.should_not_receive(:run_check)
        subject.run
      end

      context 'with a namespaced hook' do
        module DummyNamespace
          class DumbHook < Overcommit::GitHook::HookSpecificCheck
            include Overcommit::GitHook::HookRegistry
          end
        end

        let!(:dumb_hook) { DummyNamespace::DumbHook.new }

        before do
          subject.stub(:skip_checks).and_return(['dumb_hook'])
          DummyNamespace::DumbHook.stub(:new).and_return(dumb_hook)
        end

        it 'ignores the namespace' do
          dumb_hook.should_not_receive(:run_check)
          subject.run
        end
      end
    end
  end
end
