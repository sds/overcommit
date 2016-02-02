require 'spec_helper'
require 'overcommit/hook_context/pre_commit'

describe Overcommit::HookContext::PreCommit do
  let(:config) { double('config') }
  let(:args) { [] }
  let(:input) { double('input') }
  let(:context) { described_class.new(config, args, input) }

  describe '#amendment?' do
    subject { context.amendment? }

    before do
      Overcommit::Utils.stub(:parent_command).and_return(command)
    end

    context 'when amending a commit using `git commit --amend`' do
      let(:command) { 'git commit --amend' }

      it { should == true }
    end

    context 'when the parent command contains invalid byte sequence' do
      let(:command) { "git commit --amend -m \xE3M^AM^B" }

      it { should == true }
    end

    context 'when amending a commit using a git alias' do
      around do |example|
        repo do
          `git config alias.amend "commit --amend"`
          `git config alias.other-amend "commit --amend"`
          example.run
        end
      end

      context 'when using one of multiple aliases' do
        let(:command) { 'git amend' }

        it { should == true }
      end

      context 'when using another of multiple aliases' do
        let(:command) { 'git other-amend' }

        it { should == true }
      end
    end

    context 'when not amending a commit' do
      context 'using `git commit`' do
        let(:command) { 'git commit' }

        it { should == false }
      end

      context 'using a git alias containing "--amend"' do
        let(:command) { 'git no--amend' }

        around do |example|
          repo do
            `git config alias.no--amend commit`
            example.run
          end
        end

        it { should == false }
      end
    end
  end

  describe '#setup_environment' do
    subject { context.setup_environment }

    context 'when there are no staged changes' do
      around do |example|
        repo do
          echo('Hello World', 'tracked-file')
          echo('Hello Other World', 'other-tracked-file')
          `git add tracked-file other-tracked-file`
          `git commit -m "Add tracked-file and other-tracked-file"`
          echo('Hello Again', 'untracked-file')
          echo('Some more text', 'other-tracked-file', append: true)
          example.run
        end
      end

      it 'keeps already-committed files' do
        subject
        File.open('tracked-file', 'r').read.should == "Hello World\n"
      end

      it 'does not keep unstaged changes' do
        subject
        File.open('other-tracked-file', 'r').read.should == "Hello Other World\n"
      end

      it 'keeps untracked files' do
        subject
        File.open('untracked-file', 'r').read.should == "Hello Again\n"
      end

      it 'keeps modification times the same' do
        sleep 1
        expect { subject }.to_not change {
          [
            File.mtime('tracked-file'),
            File.mtime('other-tracked-file'),
            File.mtime('untracked-file')
          ]
        }
      end
    end

    context 'when there are staged changes' do
      around do |example|
        repo do
          echo('Hello World', 'tracked-file')
          echo('Hello Other World', 'other-tracked-file')
          `git add tracked-file other-tracked-file`
          `git commit -m "Add tracked-file and other-tracked-file"`
          echo('Hello Again', 'untracked-file')
          echo('Some more text', 'tracked-file', append: true)
          echo('Some more text', 'other-tracked-file', append: true)
          `git add tracked-file`
          echo('Yet some more text', 'tracked-file', append: true)
          example.run
        end
      end

      it 'keeps staged changes' do
        subject
        File.open('tracked-file', 'r').read.should == "Hello World\nSome more text\n"
      end

      it 'does not keep unstaged changes' do
        subject
        File.open('other-tracked-file', 'r').read.should == "Hello Other World\n"
      end

      it 'keeps untracked files' do
        subject
        File.open('untracked-file', 'r').read.should == "Hello Again\n"
      end

      it 'keeps modification times the same' do
        sleep 1
        expect { subject }.to_not change {
          [
            File.mtime('tracked-file'),
            File.mtime('other-tracked-file'),
            File.mtime('untracked-file')
          ]
        }
      end
    end

    context 'when renaming a file during an amendment' do
      around do |example|
        repo do
          `git commit --allow-empty -m "Initial commit"`
          touch 'some-file'
          `git add some-file`
          `git commit -m "Add file"`
          `git mv some-file renamed-file`
          example.run
        end
      end

      before do
        context.stub(:amendment?).and_return(true)
      end

      it 'does not try to update modification time of the old non-existent file' do
        File.should_receive(:mtime).with(/renamed-file/)
        File.should_not_receive(:mtime).with(/some-file/)
        subject
      end
    end

    context 'when only a submodule change is staged' do
      around do |example|
        submodule = repo do
          `git commit --allow-empty -m "Initial commit"`
        end

        repo do
          `git submodule add #{submodule} sub > #{File::NULL} 2>&1`
          `git commit -m "Add submodule"`
          echo('Hello World', 'sub/submodule-file')
          `git submodule foreach "git add submodule-file" < #{File::NULL}`
          `git submodule foreach "git commit -m \\"Another commit\\"" < #{File::NULL}`
          `git add sub`
          example.run
        end
      end

      it 'keeps staged submodule change' do
        `git config diff.submodule short`
        expect { subject }.to_not change {
          (`git diff --cached` =~ /-Subproject commit[\s\S]*\+Subproject commit/).nil?
        }.from(false)
      end
    end

    # Git cannot track Windows symlinks
    unless Overcommit::OS.windows?
      context 'when a broken symlink is staged' do
        around do |example|
          repo do
            Overcommit::Utils::FileUtils.symlink('non-existent-file', 'symlink')
            `git add symlink`
            example.run
          end
        end

        it 'does not attempt to update/restore the modification time of the file' do
          File.should_not_receive(:mtime)
          File.should_not_receive(:utime)
          subject
        end
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
          echo('Hello World', 'tracked-file')
          echo('Hello Other World', 'other-tracked-file')
          `git add tracked-file other-tracked-file`
          `git commit -m "Add tracked-file and other-tracked-file"`
          echo('Hello Again', 'untracked-file')
          echo('Some more text', 'other-tracked-file', append: true)
          example.run
        end
      end

      it 'restores the unstaged changes' do
        subject
        File.open('other-tracked-file', 'r').read.
          should == "Hello Other World\nSome more text\n"
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
        sleep 1
        expect { subject }.to_not change {
          [
            File.mtime('tracked-file'),
            File.mtime('other-tracked-file'),
            File.mtime('untracked-file')
          ]
        }
      end
    end

    context 'when there were staged changes' do
      around do |example|
        repo do
          echo('Hello World', 'tracked-file')
          echo('Hello Other World', 'other-tracked-file')
          `git add tracked-file other-tracked-file`
          `git commit -m "Add tracked-file and other-tracked-file"`
          echo('Hello Again', 'untracked-file')
          echo('Some more text', 'tracked-file', append: true)
          echo('Some more text', 'other-tracked-file', append: true)
          `git add tracked-file`
          echo('Yet some more text', 'tracked-file', append: true)
          example.run
        end
      end

      it 'restores the unstaged changes' do
        subject
        File.open('tracked-file', 'r').read.
          should == "Hello World\nSome more text\nYet some more text\n"
      end

      it 'keeps staged changes' do
        subject
        `git show :tracked-file`.should == "Hello World\nSome more text\n"
      end

      it 'keeps untracked files' do
        subject
        File.open('untracked-file', 'r').read.should == "Hello Again\n"
      end

      it 'keeps modification times the same' do
        sleep 1
        expect { subject }.to_not change {
          [
            File.mtime('tracked-file'),
            File.mtime('other-tracked-file'),
            File.mtime('untracked-file')
          ]
        }
      end
    end

    context 'when there were deleted files' do
      around do |example|
        repo do
          echo('Hello World', 'tracked-file')
          `git add tracked-file`
          `git commit -m "Add tracked-file"`
          `git rm tracked-file`
          example.run
        end
      end

      it 'deletes the file' do
        subject
        File.exist?('tracked-file').should == false
      end
    end

    context 'when only a submodule change was staged' do
      around do |example|
        submodule = repo do
          `git commit --allow-empty -m "Initial commit"`
        end

        repo do
          `git submodule add #{submodule} sub > #{File::NULL} 2>&1`
          `git commit -m "Add submodule"`
          echo('Hello World', 'sub/submodule-file')
          `git submodule foreach "git add submodule-file" < #{File::NULL}`
          `git submodule foreach "git commit -m \\"Another commit\\"" < #{File::NULL}`
          `git add sub`
          example.run
        end
      end

      it 'keeps staged submodule change' do
        `git config diff.submodule short`
        expect { subject }.to_not change {
          (`git diff --cached` =~ /-Subproject commit[\s\S]*\+Subproject commit/).nil?
        }.from(false)
      end
    end

    context 'when submodule changes were staged along with other changes' do
      around do |example|
        submodule = repo do
          `git commit --allow-empty -m "Initial commit"`
        end

        repo do
          `git submodule add #{submodule} sub > #{File::NULL} 2>&1`
          `git commit -m "Add submodule"`
          echo('Hello World', 'sub/submodule-file')
          `git submodule foreach "git add submodule-file" < #{File::NULL}`
          `git submodule foreach "git commit -m \\"Another commit\\"" < #{File::NULL}`
          echo('Hello Again', 'tracked-file')
          `git add sub tracked-file`
          example.run
        end
      end

      it 'keeps staged submodule change' do
        `git config diff.submodule short`
        expect { subject }.to_not change {
          (`git diff --cached` =~ /-Subproject commit[\s\S]*\+Subproject commit/).nil?
        }.from(false)
      end

      it 'keeps staged file change' do
        subject
        `git show :tracked-file`.should == "Hello Again\n"
      end
    end

    context 'when a submodule removal was staged' do
      around do |example|
        submodule = repo do
          `git commit --allow-empty -m "Initial commit"`
        end

        repo do
          `git submodule add #{submodule} sub > #{File::NULL} 2>&1`
          `git commit -m "Add submodule"`
          `git rm sub`
          example.run
        end
      end

      it 'does not leave behind an empty submodule directory' do
        subject
        File.exist?('sub').should == false
      end
    end
  end

  describe '#modified_files' do
    subject { context.modified_files }

    before do
      context.stub(:amendment?).and_return(false)
    end

    it 'does not include submodules' do
      submodule = repo do
        touch 'foo'
        `git add foo`
        `git commit -m "Initial commit"`
      end

      repo do
        `git submodule add #{submodule} test-sub 2>&1 > #{File::NULL}`
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
          touch('some-file')
          `git add some-file`
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
          example.run
        end
      end

      it { should be_empty }
    end

    context 'when amending last commit' do
      around do |example|
        repo do
          touch('some-file')
          `git add some-file`
          `git commit -m "Initial commit"`
          touch('other-file')
          `git add other-file`
          example.run
        end
      end

      before do
        context.stub(:amendment?).and_return(true)
      end

      it { should =~ [File.expand_path('some-file'), File.expand_path('other-file')] }
    end

    context 'when renaming a file during an amendment' do
      around do |example|
        repo do
          `git commit --allow-empty -m "Initial commit"`
          touch 'some-file'
          `git add some-file`
          `git commit -m "Add file"`
          `git mv some-file renamed-file`
          example.run
        end
      end

      before do
        context.stub(:amendment?).and_return(true)
      end

      it 'does not include the old file name in the list of modified files' do
        subject.should_not include File.expand_path('some-file')
      end
    end

    # Git cannot track Windows symlinks
    unless Overcommit::OS.windows?
      context 'when changing a symlink to a directory during an amendment' do
        around do |example|
          repo do
            `git commit --allow-empty -m "Initial commit"`
            FileUtils.mkdir 'some-directory'
            symlink('some-directory', 'some-symlink')
            `git add some-symlink some-directory`
            `git commit -m "Add file"`
            `git rm some-symlink`
            FileUtils.mkdir 'some-symlink'
            touch File.join('some-symlink', 'another-file')
            `git add some-symlink`
            example.run
          end
        end

        before do
          context.stub(:amendment?).and_return(true)
        end

        it 'does not include the directory in the list of modified files' do
          subject.should_not include File.expand_path('some-symlink')
        end
      end

      context 'when breaking a symlink during an amendment' do
        around do |example|
          repo do
            `git commit --allow-empty -m "Initial commit"`
            FileUtils.mkdir 'some-directory'
            touch File.join('some-directory', 'some-file')
            symlink('some-directory', 'some-symlink')
            `git add some-symlink some-directory`
            `git commit -m "Add file"`
            `git rm -rf some-directory`
            example.run
          end
        end

        before do
          context.stub(:amendment?).and_return(true)
        end

        it 'still includes the broken symlink in the list of modified files' do
          subject.should include File.expand_path('some-symlink')
        end
      end
    end
  end

  describe '#modified_lines_in_file' do
    let(:modified_file) { 'some-file' }
    subject { context.modified_lines_in_file(modified_file) }

    before do
      context.stub(:amendment?).and_return(false)
    end

    context 'when file contains a trailing newline' do
      around do |example|
        repo do
          File.open(modified_file, 'w') { |f| (1..3).each { |i| f.write("#{i}\n") } }
          `git add #{modified_file}`
          example.run
        end
      end

      it { should == Set.new(1..3) }
    end

    context 'when file does not contain a trailing newline' do
      around do |example|
        repo do
          File.open(modified_file, 'w') do |f|
            (1..2).each { |i| f.write("#{i}\n") }
            f.write(3)
          end

          `git add #{modified_file}`
          example.run
        end
      end

      it { should == Set.new(1..3) }
    end

    context 'when amending last commit' do
      around do |example|
        repo do
          File.open(modified_file, 'w') { |f| (1..3).each { |i| f.write("#{i}\n") } }
          `git add #{modified_file}`
          `git commit -m "Add files"`
          File.open(modified_file, 'a') { |f| f.puts 4 }
          `git add #{modified_file}`
          example.run
        end
      end

      before do
        context.stub(:amendment?).and_return(true)
      end

      it { should == Set.new(1..4) }
    end
  end
end
