# frozen_string_literal: true

require 'spec_helper'
require 'overcommit/hook_context/pre_commit'

describe Overcommit::HookContext::PreCommit, 'stash failures' do
  let(:context) { described_class.new(nil, [], nil) }

  { stash_changes: 'HookSetupFailed', restore_staged_changes: 'HookSetupFailed',
    clear_working_tree: 'HookCleanupFailed', restore_working_tree: 'HookCleanupFailed' }.
    each do |operation, exception|
    it "reports #{operation} command failures" do
      allow(Overcommit::GitRepo).to receive(:staged_submodule_removals).and_return([])
      allow(Overcommit::Utils).to receive(:execute).
        and_return(double('result', success?: false, stdout: 'output', stderr: 'failure'))
      expect { context.send(operation) }.
        to raise_error(Overcommit::Exceptions.const_get(exception),
                       /STDOUT:output.*STDERR:failure/m)
    end
  end

  it 'removes empty directories restored for staged submodule removals' do
    directory do
      Dir.mkdir('removed')
      allow(Overcommit::GitRepo).to receive(:staged_submodule_removals).
        and_return([double('submodule', path: 'removed')])
      allow(Overcommit::Utils).to receive(:execute).and_return(double('result', success?: true))
      context.send(:clear_working_tree)
      expect(Dir).not_to exist('removed')
    end
  end
end
