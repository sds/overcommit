require 'spec_helper'
require 'overcommit/hook_context/post_checkout'

describe Overcommit::HookContext::PostCheckout do
  let(:config) { double('config') }
  let(:args) { [previous_head, new_head, branch_flag] }
  let(:input) { double('input') }
  let(:previous_head) { random_hash }
  let(:new_head) { random_hash }
  let(:branch_flag) { '1' }
  let(:context) { described_class.new(config, args, input) }

  describe '#previous_head' do
    subject { context.previous_head }

    it { should == previous_head }
  end

  describe '#new_head' do
    subject { context.new_head }

    it { should == new_head }
  end

  describe '#branch_checkout?' do
    subject { context.branch_checkout? }

    context 'when the flag is 0' do
      let(:branch_flag) { '0' }

      it { should == false }
    end

    context 'when the flag is 1' do
      it { should == true }
    end
  end

  describe '#file_checkout?' do
    subject { context.file_checkout? }

    context 'when the flag is 0' do
      let(:branch_flag) { '0' }

      it { should == true }
    end

    context 'when the flag is 1' do
      it { should == false }
    end
  end

  describe '#modified_files' do
    subject { context.modified_files }

    let(:new_head) { 'HEAD' }
    let(:previous_head) { 'HEAD~' }

    it 'does not include submodules' do
      submodule = repo do
        touch 'foo'
        `git add foo`
        `git commit -m "Initial commit"`
      end

      repo do
        `git commit --allow-empty -m "Initial commit"`
        `git submodule add #{submodule} test-sub 2>&1 > #{File::NULL}`
        `git commit -m "Add submodule"`
        expect(subject).to_not include File.expand_path('test-sub')
      end
    end

    context 'when no files were modified' do
      around do |example|
        repo do
          `git commit --allow-empty -m "Initial commit"`
          `git commit --allow-empty -m "Another commit"`
          example.run
        end
      end

      it { should be_empty }
    end

    context 'when files were added' do
      around do |example|
        repo do
          `git commit --allow-empty -m "Initial commit"`
          touch('some-file')
          `git add some-file`
          `git commit -m "Add file"`
          example.run
        end
      end

      it { should == [File.expand_path('some-file')] }
    end

    context 'when files were modified' do
      around do |example|
        repo do
          touch('some-file')
          `git add some-file`
          `git commit -m "Initial commit"`
          echo('Hello', 'some-file')
          `git add some-file`
          `git commit -m "Modify file"`
          example.run
        end
      end

      it { should == [File.expand_path('some-file')] }
    end

    context 'when files were deleted' do
      around do |example|
        repo do
          touch('some-file')
          `git add some-file`
          `git commit -m "Initial commit"`
          `git rm some-file`
          `git commit -m "Delete file"`
          example.run
        end
      end

      it { should be_empty }
    end

    context 'when files were renamed' do
      around do |example|
        repo do
          touch 'some-file'
          `git add some-file`
          `git commit -m "Add file"`
          `git mv some-file renamed-file`
          `git commit -m "Rename file"`
          example.run
        end
      end

      it { should == [File.expand_path('renamed-file')] }
    end
  end
end
