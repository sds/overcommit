require 'spec_helper'
require 'overcommit/hook_context/post_rewrite'

describe Overcommit::HookContext::PostRewrite do
  let(:config) { double('config') }
  let(:input) { double('input') }
  let(:context) { described_class.new(config, args, input) }

  describe '#amend?' do
    subject { context.amend? }

    context 'when rewrite was triggered by amend' do
      let(:args) { ['amend'] }

      it { should == true }
    end

    context 'when rewrite was triggered by rebase' do
      let(:args) { ['rebase'] }

      it { should == false }
    end
  end

  describe '#rebase?' do
    subject { context.rebase? }

    context 'when rewrite was triggered by amend' do
      let(:args) { ['amend'] }

      it { should == false }
    end

    context 'when rewrite was triggered by rebase' do
      let(:args) { ['rebase'] }

      it { should == true }
    end
  end

  describe '#rewritten_commits' do
    subject(:rewritten_commits) { context.rewritten_commits }

    let(:old_hash_1) { random_hash }
    let(:new_hash_1) { random_hash }
    let(:old_hash_2) { random_hash }
    let(:new_hash_2) { random_hash }

    context 'when rewrite was triggered by amend' do
      let(:args) { ['amend'] }

      before do
        input.stub(:read).and_return("#{old_hash_1} #{new_hash_1}\n")
      end

      it 'should parse rewritten commit info from the input' do
        rewritten_commits.length.should == 1
        rewritten_commits[0].old_hash.should == old_hash_1
        rewritten_commits[0].new_hash.should == new_hash_1
      end
    end

    context 'when rewrite was triggered by rebase' do
      let(:args) { ['rebase'] }

      before do
        input.stub(:read).and_return([
          "#{old_hash_1} #{new_hash_1}",
          "#{old_hash_2} #{new_hash_2}"
        ].join("\n"))
      end

      it 'should parse rewritten commit info from the input' do
        rewritten_commits.length.should == 2
        rewritten_commits[0].old_hash.should == old_hash_1
        rewritten_commits[0].new_hash.should == new_hash_1
        rewritten_commits[1].old_hash.should == old_hash_2
        rewritten_commits[1].new_hash.should == new_hash_2
      end
    end
  end

  describe '#modified_files' do
    subject { context.modified_files }

    before do
      context.stub(:rewritten_commits).and_return(rewritten_commits)
    end

    context 'when rewrite was triggered by amend' do
      let(:args) { ['amend'] }
      let(:rewritten_commits) { [double(old_hash: 'HEAD@{1}', new_hash: 'HEAD')] }

      it 'does not include submodules' do
        submodule = repo do
          touch 'foo'
          `git add foo`
          `git commit -m "Initial commit"`
        end

        repo do
          `git commit --allow-empty -m "Initial commit"`
          `git submodule add #{submodule} test-sub 2>&1 > #{File::NULL}`
          `git commit --amend -m "Add submodule"`
          expect(subject).to_not include File.expand_path('test-sub')
        end
      end

      context 'when no files were modified' do
        around do |example|
          repo do
            `git commit --allow-empty -m "Initial commit"`
            `git commit --amend --allow-empty -m "Another commit"`
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
            `git commit --amend -m "Add file"`
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
            `git commit --amend -m "Modify file"`
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
            `git commit --amend --allow-empty -m "Delete file"`
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
            `git commit --amend -m "Rename file"`
            example.run
          end
        end

        it { should == [File.expand_path('renamed-file')] }
      end

      # Git cannot track Windows symlinks
      unless Overcommit::OS.windows?
        context 'when changing a symlink to a directory during an amendment' do
          around do |example|
            repo do
              FileUtils.mkdir 'some-directory'
              symlink('some-directory', 'some-symlink')
              `git add some-symlink some-directory`
              `git commit -m "Add file"`
              `git rm some-symlink`
              FileUtils.mkdir 'some-symlink'
              touch File.join('some-symlink', 'another-file')
              `git add some-symlink`
              `git commit --amend -m "Change symlink to directory"`
              example.run
            end
          end

          it 'does not include the directory in the list of modified files' do
            subject.should_not include File.expand_path('some-symlink')
          end
        end

        context 'when breaking a symlink during an amendment' do
          around do |example|
            repo do
              FileUtils.mkdir 'some-directory'
              touch File.join('some-directory', 'some-file')
              symlink('some-directory', 'some-symlink')
              `git add some-symlink some-directory`
              `git commit -m "Add file"`
              `git rm -rf some-directory`
              `git commit --amend -m "Remove directory to break symlink"`
              example.run
            end
          end

          it 'does not include the broken symlink in the list of modified files' do
            subject.should_not include File.expand_path('some-symlink')
          end
        end
      end
    end
  end
end
