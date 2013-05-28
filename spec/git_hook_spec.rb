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
  end
end
