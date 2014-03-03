require 'spec_helper'
require 'overcommit/hook_context/pre_commit'

describe Overcommit::HookContext::PreCommit do
  let(:config) { double('config') }
  let(:args) { [] }
  let(:input) { '' }
  let(:context) { described_class.new(config, args, input) }

  describe '#setup_environment' do
    subject { context.setup_environment }

    context 'when there are no staged changes' do
      around do |example|
        repo do
          `echo "Hello World" > tracked-file`
          `git add tracked-file`
          `git commit -m "Add tracked-file"`
          `echo "Hello Again" > untracked-file`
          example.run
        end
      end

      it 'keeps already-committed files' do
        subject
        File.open('tracked-file', 'r').read == 'Hello World'
      end

      it 'keeps untracked files' do
        subject
        File.open('untracked-file', 'r').read == 'Hello Again'
      end

      it 'keeps modification times the same' do
        expect { subject }.
          to_not change { [File.mtime('tracked-file'), File.mtime('untracked-file')] }
      end
    end

    context 'when there are staged changes' do
      around do |example|
        repo do
          `echo "Hello World" > tracked-file`
          `git add tracked-file`
          `git commit -m "Add tracked-file"`
          `echo "Hello Again" > untracked-file`
          `echo "Some more text" >> tracked-file`
          `git add tracked-file`
          `echo "Yet some more text" >> tracked-file`
          example.run
        end
      end

      it 'keeps staged changes' do
        subject
        File.open('tracked-file', 'r').read == 'Hello WorldSome more text'
      end

      it 'keeps untracked files' do
        subject
        File.open('untracked-file', 'r').read == 'Hello Again'
      end

      it 'keeps modification times the same' do
        expect { subject }.
          to_not change { [File.mtime('tracked-file'), File.mtime('untracked-file')] }
      end
    end
  end

  describe '#cleanup_environment' do
    subject { context.cleanup_environment }

    before do
      context.setup_environment
    end

    context 'when there were no staged changes' do
      around do |example|
        repo do
          `echo "Hello World" > tracked-file`
          `git add tracked-file`
          `git commit -m "Add tracked-file"`
          `echo "Hello Again" > untracked-file`
          example.run
        end
      end

      it 'keeps already-committed files' do
        subject
        File.open('tracked-file', 'r').read.should == "Hello World\n"
      end

      it 'keeps untracked files' do
        subject
        File.open('untracked-file', 'r').read.should == "Hello Again\n"
      end

      it 'keeps modification times the same' do
        expect { subject }.
          to_not change { [File.mtime('tracked-file'), File.mtime('untracked-file')] }
      end
    end

    context 'when there were staged changes' do
      around do |example|
        repo do
          `echo "Hello World" > tracked-file`
          `git add tracked-file`
          `git commit -m "Add tracked-file"`
          `echo "Hello Again" > untracked-file`
          `echo "Some more text" >> tracked-file`
          `git add tracked-file`
          `echo "Yet some more text" >> tracked-file`
          example.run
        end
      end

      it 'restores the unstaged changes' do
        subject
        File.open('tracked-file', 'r').read.
          should == "Hello World\nSome more text\nYet some more text\n"
      end

      it 'keeps untracked files' do
        subject
        File.open('untracked-file', 'r').read.should == "Hello Again\n"
      end

      it 'keeps modification times the same' do
        expect { subject }.
          to_not change { [File.mtime('tracked-file'), File.mtime('untracked-file')] }
      end
    end

    context 'when there were deleted files' do
      around do |example|
        repo do
          `echo "Hello World" > tracked-file`
          `git add tracked-file`
          `git commit -m "Add tracked-file"`
          `git rm tracked-file`
          example.run
        end
      end

      it 'deletes the file' do
        subject
        File.exist?('tracked-file').should be_false
      end
    end
  end

  describe '#modified_files' do
    subject { context.modified_files }

    it 'does not include submodules' do
      submodule = repo do
        `touch foo`
        `git add foo`
        `git commit -m "Initial commit"`
      end

      repo do
        `git submodule add #{submodule} test-sub`
        expect(subject).to_not include File.expand_path('test-sub')
      end
    end

    context 'when no files were staged' do
      around do |example|
        repo do
          example.run
        end
      end

      it { should be_empty }
    end

    context 'when files were added' do
      around do |example|
        repo do
          FileUtils.touch('some-file')
          `git add some-file`
          example.run
        end
      end

      it { should == [File.expand_path('some-file')] }
    end

    context 'when files were modified' do
      around do |example|
        repo do
          FileUtils.touch('some-file')
          `git add some-file`
          `git commit -m 'Initial commit'`
          `echo Hello > some-file`
          `git add some-file`
          example.run
        end
      end

      it { should == [File.expand_path('some-file')] }
    end

    context 'when files were deleted' do
      around do |example|
        repo do
          FileUtils.touch('some-file')
          `git add some-file`
          `git commit -m 'Initial commit'`
          `git rm some-file`
          example.run
        end
      end

      it { should be_empty }
    end
  end
end
