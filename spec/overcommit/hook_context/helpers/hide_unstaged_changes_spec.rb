# frozen_string_literal: true

require 'spec_helper'
require 'overcommit/hook_context/pre_commit'
require 'overcommit/hook_context/commit_msg'

[Overcommit::HookContext::PreCommit, Overcommit::HookContext::CommitMsg].each do |hook_context|
  describe hook_context do
    describe 'hiding unstaged changes alongside staged deletions and renames' do
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

  describe hook_context, 'hook side effects' do
    let(:context) { described_class.new(nil, [], nil) }
    let(:original) { (1..20).map { |line| "line #{line}\n" }.join }
    let(:staged) { original.sub('line 1', 'staged line 1') }
    let(:unstaged) { staged.sub('line 20', 'unstaged line 20') }

    around do |example|
      repo do
        File.write('source.txt', original)
        echo('remove me', 'removed.txt')
        shell(%w[git add .]).status.should == 0
        shell(%w[git commit -m Initial]).status.should == 0
        File.write('source.txt', staged)
        shell(%w[git add source.txt]).status.should == 0
        File.write('source.txt', unstaged)
        example.run
      end
    end

    def patches
      Dir[File.join(File.dirname(Overcommit::Utils.git_path('index')), 'overcommit-*.patch')]
    end

    [false, true].each do |stage_changes|
      description = stage_changes ? 'in the index' : 'unstaged'
      it "keeps hook edits #{description} and restores user edits" do
        context.setup_environment
        hook_contents = staged.sub('line 2', 'formatted line 2')
        File.write('source.txt', hook_contents)
        shell(%w[git add source.txt]).status.should == 0 if stage_changes
        hook_time = Time.at(1_000_000_000)
        File.utime(hook_time, hook_time, 'source.txt')
        context.cleanup_environment

        File.read('source.txt').should == hook_contents.sub('line 20', 'unstaged line 20')
        shell(%w[git show :source.txt]).stdout.should == (stage_changes ? hook_contents : staged)
        File.mtime('source.txt').should_not == hook_time # Applying user edits updates the file.
        patches.should be_empty
      end
    end

    it 'retains newly created, removed, renamed, and staged files' do
      context.setup_environment
      echo('new file', 'generated.txt')
      echo('untracked file', 'untracked.txt')
      shell(%w[git add generated.txt]).status.should == 0
      shell(%w[git rm removed.txt]).status.should == 0
      shell(%w[git mv generated.txt renamed.txt]).status.should == 0
      index = shell(%w[git write-tree]).stdout
      context.cleanup_environment

      shell(%w[git write-tree]).stdout.should == index
      File.read('renamed.txt').should == "new file\n"
      File.read('untracked.txt').should == "untracked file\n"
      File.exist?('removed.txt').should == false
      File.exist?('generated.txt').should == false
      File.read('source.txt').should == unstaged
    end

    it 'keeps edits and modification times for files without hidden changes' do
      context.setup_environment
      echo('hook changed another file', 'removed.txt')
      hook_time = Time.at(1_000_000_000)
      File.utime(hook_time, hook_time, 'removed.txt')
      context.cleanup_environment

      File.read('removed.txt').should == "hook changed another file\n"
      File.mtime('removed.txt').should == hook_time
    end

    it 'does not resurrect files deleted by hooks' do
      context.setup_environment
      File.unlink('removed.txt')
      context.cleanup_environment
      File.exist?('removed.txt').should == false
    end

    it 'preserves hook changes when restoring conflicting unstaged changes fails' do
      context.setup_environment
      patch = patches.fetch(0)
      File.file?(patch).should == true
      # A garbage collection must never remove the recovery data.
      GC.start
      File.file?(patch).should == true
      File.write('source.txt', staged.sub('line 20', 'hook line 20'))
      shell(%w[git add source.txt]).status.should == 0
      index = shell(%w[git write-tree]).stdout

      expect { context.cleanup_environment }.
        to raise_error(Overcommit::Exceptions::HookCleanupFailed) { |error|
          error.message.should include(patch, 'git apply --whitespace=nowarn --')
        }
      shell(%w[git write-tree]).stdout.should == index
      File.read('source.txt').should include 'hook line 20'
      File.read(patch).should include 'unstaged line 20'

      # Resolve the conflicting hook edit, then follow the advertised command.
      File.write('source.txt', staged)
      shell(['git', 'apply', '--whitespace=nowarn', '--', patch]).status.should == 0
      File.read('source.txt').should == unstaged
      shell(%w[git write-tree]).stdout.should == index
    end

    it 'keeps a patch and the original state when hiding changes fails' do
      index = shell(%w[git write-tree]).stdout
      allow(Overcommit::Utils).to receive(:execute).and_call_original
      allow(Overcommit::Utils).to receive(:execute).
        with(array_including('apply', '--reverse')).
        and_return(Overcommit::Subprocess::Result.new(128, 'output', 'file locked'))

      expect { context.setup_environment }.
        to raise_error(Overcommit::Exceptions::HookSetupFailed) { |error|
          error.message.should include('STDOUT:output', 'STDERR:file locked', patches.fetch(0))
        }
      File.read('source.txt').should == unstaged
      shell(%w[git write-tree]).stdout.should == index
    end

    it 'does not modify anything when generating the patch fails' do
      allow(Overcommit::Utils).to receive(:execute).and_call_original
      allow(Overcommit::Utils).to receive(:execute).with(array_including('diff', '--binary')).
        and_return(Overcommit::Subprocess::Result.new(128, '', 'corrupt index'))

      expect { context.setup_environment }.
        to raise_error(Overcommit::Exceptions::HookSetupFailed, /corrupt index/)
      File.read('source.txt').should == unstaged
      patches.should be_empty
    end

    it 'leaves changes untouched if the backup cannot be written' do
      allow(Tempfile).to receive(:create).and_raise(Errno::EACCES)
      expect { context.setup_environment }.to raise_error(Errno::EACCES)
      File.read('source.txt').should == unstaged
    end

    it 'can clean up twice without applying edits twice' do
      context.setup_environment
      context.cleanup_environment
      context.cleanup_environment
      File.read('source.txt').should == unstaged
    end

    it 'does not need a commit identity or signing key' do
      shell(['git', 'config', 'user.name', '']).status.should == 0
      shell(['git', 'config', 'user.email', '']).status.should == 0
      shell(%w[git config commit.gpgsign true]).status.should == 0
      context.setup_environment
      context.cleanup_environment
      File.read('source.txt').should == unstaged
    end

    it 'leaves merge and cherry-pick metadata byte-for-byte intact' do
      metadata = %w[MERGE_HEAD MERGE_MSG MERGE_MODE CHERRY_PICK_HEAD].map do |name|
        path = Overcommit::Utils.git_path(name)
        File.binwrite(path, "operation state\r\n")
        [path, File.binread(path)]
      end.to_h
      context.setup_environment
      metadata.each { |path, contents| File.binread(path).should == contents }
      context.cleanup_environment
      metadata.each { |path, contents| File.binread(path).should == contents }
    end

    it 'ignores external diff, text conversion, color, prefixes, and configured context' do
      shell(%w[git config diff.external nonexistent-command]).status.should == 0
      shell(%w[git config diff.noprefix true]).status.should == 0
      shell(%w[git config diff.context 100]).status.should == 0
      shell(%w[git config color.ui always]).status.should == 0
      echo('source.txt diff=custom', '.gitattributes')
      shell(%w[git config diff.custom.textconv nonexistent-command]).status.should == 0
      context.setup_environment
      File.read('source.txt').should == staged
      context.cleanup_environment
      File.read('source.txt').should == unstaged
    end

    it 'restores unstaged deletions and intent-to-add files without changing the index' do
      File.unlink('removed.txt')
      echo('intent to add', 'new.txt')
      shell(%w[git add --intent-to-add new.txt]).status.should == 0
      index = shell(%w[git ls-files --stage -z]).stdout
      context.setup_environment
      File.read('removed.txt').should == "remove me\n"
      File.exist?('new.txt').should == false
      context.cleanup_environment
      File.exist?('removed.txt').should == false
      File.read('new.txt').should == "intent to add\n"
      shell(%w[git ls-files --stage -z]).stdout.should == index
    end

    it 'preserves binary data and unusual file names' do
      names = ["space and 'quote'.bin", 'unicodé.bin', '-dash.bin']
      names << "tab\tand\nnewline.bin" unless Overcommit::OS.windows?
      names.each { |name| File.binwrite(name, "\x00\xFFstaged\r\n") }
      shell(['git', 'add', '--'] + names).status.should == 0
      names.each { |name| File.binwrite(name, "\x00\xFEunstaged\r\n") }
      context.setup_environment
      names.each { |name| File.binread(name).should == "\x00\xFFstaged\r\n".b }
      context.cleanup_environment
      names.each { |name| File.binread(name).should == "\x00\xFEunstaged\r\n".b }
    end

    it 'preserves symlinks, including broken targets, without modifying their targets' do
      echo('target', 'target.txt')
      symlink('target.txt', 'link')
      shell(%w[git add link]).status.should == 0
      File.unlink('link')
      symlink('missing.txt', 'link')
      context.setup_environment
      File.readlink('link').should == 'target.txt'
      context.cleanup_environment
      File.readlink('link').should == 'missing.txt'
      File.read('target.txt').should == "target\n"
      File.exist?('missing.txt').should == false
    end

    it 'handles file type changes without following symlinks' do
      File.unlink('removed.txt')
      symlink('source.txt', 'removed.txt')
      context.setup_environment
      File.symlink?('removed.txt').should == false
      File.read('removed.txt').should == "remove me\n"
      context.cleanup_environment
      File.readlink('removed.txt').should == 'source.txt'
      File.read('source.txt').should == unstaged
    end

    it 'restores patches at their new positions after a hook inserts lines' do
      context.setup_environment
      File.write('source.txt', "new header\n#{staged}")
      context.cleanup_environment
      File.read('source.txt').should == "new header\n#{unstaged}"
    end

    it 'does not partially restore other files when one file conflicts' do
      echo('unstaged removal edit', 'removed.txt')
      context.setup_environment
      File.write('source.txt', 'conflicting hook content')
      expect { context.cleanup_environment }.
        to raise_error(Overcommit::Exceptions::HookCleanupFailed)
      File.read('removed.txt').should == "remove me\n"
      File.read('source.txt').should == 'conflicting hook content'
      patches.should_not be_empty
    end

    it 'restores timestamps when hiding and restoring an intent-to-add file' do
      echo('intent to add', 'intent.txt')
      shell(%w[git add --intent-to-add intent.txt]).status.should == 0
      time = Time.at(1_000_000_000)
      File.utime(time, time, 'intent.txt')
      context.setup_environment
      context.cleanup_environment
      File.mtime('intent.txt').should == time
    end

    it 'restores timestamps when unstaged contents replace a staged symlink' do
      symlink('target.txt', 'link')
      shell(%w[git add link]).status.should == 0
      File.unlink('link')
      echo('replaced link', 'link')
      time = Time.at(1_000_000_000)
      File.utime(time, time, 'link')
      context.setup_environment
      context.cleanup_environment
      File.read('link').should == "replaced link\n"
      File.mtime('link').should == time
    end

    [false, true].each do |windows|
      it "quotes recovery paths for #{windows ? 'PowerShell' : 'POSIX shells'}" do
        allow(Overcommit::OS).to receive(:windows?).and_return(windows)
        path = "C:/path with 'quotes'/backup.patch"
        context.instance_variable_set(:@unstaged_patch, path)
        result = Overcommit::Subprocess::Result.new(1, '', 'conflict')
        expected = windows ? "'C:/path with ''quotes''/backup.patch'" : Shellwords.escape(path)
        expect do
          context.send(:check_patch_result, result, Overcommit::Exceptions::HookCleanupFailed)
        end.to raise_error(Overcommit::Exceptions::HookCleanupFailed) { |error|
          error.message.should include expected
          error.message.should include 'in PowerShell' if windows
        }
      end
    end

    it 'caches the initial commit check, including false results' do
      expect(Overcommit::GitRepo).to receive(:initial_commit?).once.and_return(false)
      2.times { context.initial_commit?.should == false }
    end
  end
end

describe Overcommit::HookContext::PreCommit, 'repository variants' do
  let(:context) { described_class.new(nil, [], nil) }

  it 'uses the active alternate index and preserves edits to it made by hooks' do
    repo do
      echo('original', 'file.txt')
      shell(%w[git add .]).status.should == 0
      shell(%w[git commit -m Initial]).status.should == 0
      default_index = shell(%w[git write-tree]).stdout
      alternate_index = File.expand_path('.git/alternate-index')
      FileUtils.cp('.git/index', alternate_index)
      Overcommit::Utils.with_environment('GIT_INDEX_FILE' => alternate_index,
                                         'GIT_LITERAL_PATHSPECS' => '1') do
        echo('staged', 'file.txt')
        shell(%w[git add file.txt]).status.should == 0
        echo('unstaged', 'file.txt', append: true)
        context.setup_environment
        File.read('file.txt').should == "staged\n"
        echo('generated', 'generated.txt')
        shell(%w[git add generated.txt]).status.should == 0
        index = shell(%w[git write-tree]).stdout
        context.cleanup_environment
        shell(%w[git write-tree]).stdout.should == index
        File.read('file.txt').should == "staged\nunstaged\n"
      end
      shell(%w[git write-tree]).stdout.should == default_index
    end
  end

  it 'keeps recovery patches in the linked worktree Git directory' do
    repo do
      echo('original', 'file.txt')
      shell(%w[git add .]).status.should == 0
      shell(%w[git commit -m Initial]).status.should == 0
      main_git_dir = File.expand_path('.git')
      linked = File.join(File.dirname(Dir.pwd), 'linked-worktree')
      shell(['git', 'worktree', 'add', '-b', 'linked', linked]).status.should == 0
      Dir.chdir(linked) do
        echo('unstaged', 'file.txt')
        context.setup_environment
        patches = Dir[File.join(main_git_dir, 'worktrees', '*', 'overcommit-*.patch')]
        patches.size.should == 1
        File.file?(patches.first).should == true
        Dir[File.join(main_git_dir, 'overcommit-*.patch')].should be_empty
        context.cleanup_environment
        File.read('file.txt').should == "unstaged\n"
        File.exist?(patches.first).should == false
      end
    end
  end

  it 'preserves CRLF contents with automatic line ending conversion' do
    repo do
      shell(%w[git config core.autocrlf true]).status.should == 0
      File.binwrite('file.txt', "staged\r\n")
      shell(%w[git add .]).status.should == 0
      File.binwrite('file.txt', "staged\r\nunstaged\r\n")
      context.setup_environment
      File.binread('file.txt').should == "staged\r\n"
      context.cleanup_environment
      File.binread('file.txt').should == "staged\r\nunstaged\r\n"
    end
  end

  it 'restores unstaged executable permission changes' do
    skip 'Windows does not support POSIX executable bits' if Overcommit::OS.windows?

    repo do
      shell(%w[git config core.filemode true]).status.should == 0
      echo('staged', 'file.txt')
      shell(%w[git add .]).status.should == 0
      File.chmod(0o755, 'file.txt')
      context.setup_environment
      (File.stat('file.txt').mode & 0o111).should == 0
      context.cleanup_environment
      (File.stat('file.txt').mode & 0o111).should == 0o111
    end
  end
end

describe Overcommit::HookContext::PreCommit, 'timestamp collection' do
  it 'ignores missing files while storing modification times' do
    repo do
      context = described_class.new(nil, [], nil)
      allow(context).to receive(:modified_files).and_return(['missing.rb'])
      allow(Overcommit::GitRepo).to receive(:modified_files).with(staged: false).and_return([])
      expect(File).not_to receive(:mtime)
      expect { context.send(:store_modified_times) }.not_to raise_error
    end
  end
end
