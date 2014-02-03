require 'spec_helper'
require 'overcommit/hook_context/pre_commit'

describe Overcommit::HookContext::PreCommit do
  let(:config) { double('context') }
  let(:args) { [] }
  let(:input) { '' }
  let(:context) { described_class.new(config, args, input) }

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
