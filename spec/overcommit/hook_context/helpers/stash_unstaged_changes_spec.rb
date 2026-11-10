# frozen_string_literal: true

require 'spec_helper'
require 'overcommit/hook_context/pre_commit'
require 'overcommit/hook_context/commit_msg'

[Overcommit::HookContext::PreCommit, Overcommit::HookContext::CommitMsg].each do |hook_context|
  describe hook_context do
    describe 'stashing staged deletions and renames' do
      let(:context) { described_class.new(nil, [], nil) }
      let(:renamed_file) { 'renamed file.rb' }

      around do |example|
        repo do
          echo('Renamed content', 'original.rb')
          echo('Deleted content', 'deleted.rb')
          echo('Partially staged content', 'partial.rb')
          echo('Unchanged content', 'other.rb')
          shell(%w[git add .]).status.should == 0
          shell(%w[git commit -m Initial]).status.should == 0

          echo('Previous stash', 'other.rb')
          shell(%w[git stash save --quiet previous-stash]).status.should == 0
          shell(['git', 'mv', 'original.rb', renamed_file]).status.should == 0
          shell(%w[git rm deleted.rb]).status.should == 0
          echo('Staged addition', 'partial.rb', append: true)
          shell(%w[git add partial.rb]).status.should == 0
          echo('Unstaged addition', 'partial.rb', append: true)
          echo('Unstaged rename edit', renamed_file, append: true)
          echo('Unstaged other edit', 'other.rb', append: true)
          echo('Untracked content', 'untracked.rb')
          example.run
        end
      end

      before do
        allow(context).to receive(:amendment?).and_return(false)
      end

      def repository_state
        {
          head: shell(%w[git rev-parse HEAD]).stdout,
          index: shell(%w[git write-tree]).stdout,
          status: shell(%w[git status --porcelain -z]).stdout,
          staged_diff: shell(%w[git diff --cached --binary]).stdout,
          unstaged_diff: shell(%w[git diff --binary]).stdout,
          files: Dir['*.rb'].sort.map { |path| [path, File.binread(path)] },
          stashes: shell(%w[git stash list]).stdout,
        }
      end

      # Git's scripted stash restored the index without updating the working tree,
      # then checked out modified index entries. Deleted paths stayed on disk.
      # Emulate those operations with real Git commands so this regression is
      # exercised even on Git versions whose --keep-index has since been fixed.
      def emulate_legacy_stash
        allow(Overcommit::Utils).to receive(:execute).and_wrap_original do |original, args, *rest|
          if args.include?('stash') && args.include?('--keep-index')
            result = original.call(args - ['--keep-index'], *rest)
            if result.success?
              shell(%w[git read-tree --reset stash@{0}^2]).status.should == 0
              modified = shell(%w[git ls-files -z --modified]).stdout
              Overcommit::Subprocess.spawn(%w[git checkout-index -z --force --stdin],
                                           input: modified).status.should == 0
            end
            result
          else
            original.call(args, *rest)
          end
        end
      end

      ['current Git', 'legacy Git stash'].each do |git_implementation|
        context "with #{git_implementation}" do
          before { emulate_legacy_stash if git_implementation == 'legacy Git stash' }

          it 'exposes the staged tree without resurrecting deleted paths or moving HEAD' do
            head = shell(%w[git rev-parse HEAD]).stdout
            index = shell(%w[git write-tree]).stdout
            context.setup_environment

            File.exist?('original.rb').should == false
            File.exist?('deleted.rb').should == false
            File.read(renamed_file).should == "Renamed content\n"
            File.read('partial.rb').should == "Partially staged content\nStaged addition\n"
            File.read('other.rb').should == "Unchanged content\n"
            File.read('untracked.rb').should == "Untracked content\n"
            shell(%w[git rev-parse HEAD]).stdout.should == head
            shell(%w[git write-tree]).stdout.should == index
          end

          it 'restores all staged and unstaged changes and preserves the previous stash' do
            state = repository_state
            context.setup_environment
            context.cleanup_environment

            repository_state.should == state
          end
        end
      end

      {
        'restoring the staged tree' => %w[git read-tree --reset -u stash@{0}^2],
        'clearing the working tree' => %w[git reset --hard],
        'restoring the working tree' => %w[git stash pop --index],
      }.each do |operation, command|
        it "preserves the stash and explains recovery when #{operation} fails" do
          state = repository_state
          result = Overcommit::Subprocess::Result.new(128, '', 'fatal: file is locked')
          allow(Overcommit::Utils).to receive(:execute).and_call_original
          allow(Overcommit::Utils).to receive(:execute).with(command).and_return(result)
          error = if operation == 'restoring the staged tree'
                    Overcommit::Exceptions::HookSetupFailed
                  else
                    Overcommit::Exceptions::HookCleanupFailed
                  end

          stash_commit = nil
          expect do
            context.setup_environment
            context.cleanup_environment
          end.to raise_error(error) { |failure|
            stash_commit = shell(%w[git rev-parse stash@{0}]).stdout.strip
            failure.message.should include 'fatal: file is locked'
            failure.message.should include "git stash branch overcommit-recovery #{stash_commit}"
          }

          # Release the simulated lock and follow the advertised recovery command.
          allow(Overcommit::Utils).to receive(:execute).with(command).and_call_original
          shell(%w[git reset --hard]).status.should == 0
          shell(['git', 'stash', 'branch', 'overcommit-recovery', stash_commit]).status.should == 0
          repository_state.reject { |key, _| key == :stashes }.
            should == state.reject { |key, _| key == :stashes }
          shell(%w[git stash list]).stdout.should include 'previous-stash'
        end
      end

      it 'leaves the previous stash alone if there are no longer any changes to stash' do
        shell(%w[git reset --hard]).status.should == 0
        state = repository_state
        # Simulate changes disappearing between the initial check and git stash.
        allow(context).to receive(:unstaged_changes?).and_return(true)
        expect(context).not_to receive(:restore_staged_changes)

        context.setup_environment
        context.cleanup_environment

        repository_state.should == state
      end
    end
  end
end
