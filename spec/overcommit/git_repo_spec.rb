require 'spec_helper'

describe Overcommit::GitRepo do
  describe '.submodule_statuses' do
    let(:options) { {} }
    subject { described_class.submodule_statuses(options) }

    context 'when repo contains no submodules' do
      around do |example|
        repo do
          example.run
        end
      end

      it { should be_empty }
    end

    context 'when repo contains submodules' do
      around do |example|
        nested_submodule = repo do
          `git commit --allow-empty -m "Initial commit"`
        end

        submodule = repo do
          `git submodule add #{nested_submodule} nested-sub 2>&1 > #{File::NULL}`
          `git commit -m "Add nested submodule"`
        end

        repo do
          `git submodule add #{submodule} sub 2>&1 > #{File::NULL}`
          example.run
        end
      end

      it 'returns the submodule statuses' do
        subject.map(&:path).should == ['sub']
      end

      context 'when recursive flag is specified' do
        let(:options) { { recursive: true } }

        it 'returns submodule statuses including nested submodules' do
          subject.map(&:path).sort.should == ['sub', 'sub/nested-sub']
        end
      end
    end
  end

  describe '.extract_modified_lines' do
    let(:file) { 'file.txt' }
    let(:options) { {} }

    subject { described_class.extract_modified_lines(file, options) }

    around do |example|
      repo do
        echo("Hello World\nHow are you?", file)
        `git add file.txt`
        `git commit -m "Initial commit"`
        example.run
      end
    end

    context 'when no lines were modified' do
      it { should be_empty }
    end

    context 'when lines were added' do
      before do
        echo('Hello Again', file, append: true)
      end

      it 'includes the added lines' do
        subject.to_a.should == [3]
      end
    end

    context 'when lines were removed' do
      before do
        echo('Hello World', file)
      end

      it { should be_empty }
    end
  end

  describe '.modified_files' do
    let(:options) { {} }
    subject { described_class.modified_files(options) }

    around do |example|
      repo do
        example.run
      end
    end

    context 'when `staged` option is set' do
      let(:options) { { staged: true } }

      context 'when files were added' do
        before do
          touch 'added.txt'
          `git add added.txt`
        end

        it { should == [File.expand_path('added.txt')] }
      end

      context 'when files were renamed' do
        before do
          touch 'file.txt'
          `git add file.txt`
          `git commit -m "Initial commit"`
          `git mv file.txt renamed.txt`
        end

        it { should == [File.expand_path('renamed.txt')] }
      end

      context 'when files were modified' do
        before do
          touch 'file.txt'
          `git add file.txt`
          `git commit -m "Initial commit"`
          echo('Modification', 'file.txt', append: true)
          `git add file.txt`
        end

        it { should == [File.expand_path('file.txt')] }
      end

      context 'when files were deleted' do
        before do
          touch 'file.txt'
          `git add file.txt`
          `git commit -m "Initial commit"`
          `git rm file.txt`
        end

        it { should == [] }
      end

      context 'when submodules were added' do
        let(:submodule) do
          repo do
            `git commit --allow-empty -m "Initial commit"`
          end
        end

        before do
          `git submodule add #{submodule} sub 2>&1 > #{File::NULL}`
        end

        it { should_not include File.expand_path('sub') }
      end
    end
  end

  describe '.list_files' do
    let(:paths) { [] }
    let(:options) { {} }
    subject { described_class.list_files(paths, options) }

    around do |example|
      repo do
        `git commit --allow-empty -m "Initial commit"`
        example.run
      end
    end

    context 'when path includes a submodule directory' do
      let(:submodule_dir) { 'sub-repo' }

      before do
        submodule = repo do
          `git commit --allow-empty -m "Submodule commit"`
        end

        `git submodule add #{submodule} #{submodule_dir} 2>&1 > #{File::NULL}`
        `git commit -m "Add submodule"`
      end

      it { should_not include(File.expand_path(submodule_dir)) }
    end

    context 'when listing contents of a directory' do
      let(:dir) { 'some-dir' }
      let(:paths) { [dir + File::SEPARATOR] }

      before do
        FileUtils.mkdir(dir)
      end

      context 'when directory is empty' do
        it { should be_empty }
      end

      context 'when directory contains a file' do
        let(:file) { "#{dir}/file" }

        before do
          touch(file)
          `git add "#{file}"`
          `git commit -m "Add file"`
        end

        context 'when path contains no spaces' do
          it { should include(File.expand_path(file)) }
        end

        context 'when path contains spaces' do
          let(:dir) { 'some dir' }

          it { should include(File.expand_path(file)) }
        end
      end
    end
  end

  describe '.tracked?' do
    subject { described_class.tracked?(file) }

    around do |example|
      repo do
        touch 'untracked'
        touch 'tracked'
        `git add tracked`
        `git commit -m "Initial commit"`
        touch 'staged'
        `git add staged`
        example.run
      end
    end

    context 'when file is untracked' do
      let(:file) { 'untracked' }

      it { should == false }
    end

    context 'when file is committed' do
      let(:file) { 'tracked' }

      it { should == true }
    end

    context 'when file is staged' do
      let(:file) { 'staged' }

      it { should == true }
    end
  end

  describe '.all_files' do
    subject { described_class.all_files }

    let(:submodule) do
      repo do
        `git commit --allow-empty -m "Initial commit"`
      end
    end

    around do |example|
      repo do
        touch 'untracked'
        touch 'tracked'
        `git add tracked`
        `git commit -m "Initial commit"`
        `git submodule add #{submodule} sub 2>&1 > #{File::NULL}`
        touch 'staged'
        `git add staged`
        example.run
      end
    end

    it { should include(*%w[tracked staged].map { |file| File.expand_path(file) }) }
    it { should_not include File.expand_path('sub') }
  end

  describe '.initial_commit?' do
    subject { described_class.initial_commit? }

    context 'when there are no existing commits in the repository' do
      around do |example|
        repo do
          example.run
        end
      end

      it { should == true }
    end

    context 'when there are commits in the repository' do
      around do |example|
        repo do
          `git commit --allow-empty -m "Initial commit"`
          example.run
        end
      end

      it { should == false }
    end
  end

  describe '.staged_submodule_removals' do
    subject { described_class.staged_submodule_removals }

    around do |example|
      submodule = repo do
        `git commit --allow-empty -m "Submodule commit"`
      end

      repo do
        `git submodule add #{submodule} sub-repo 2>&1 > #{File::NULL}`
        `git commit -m "Initial commit"`
        example.run
      end
    end

    context 'when there are no submodule removals staged' do
      it { should be_empty }
    end

    context 'when there are submodule additions staged' do
      before do
        another_submodule = repo do
          `git commit --allow-empty -m "Another submodule"`
        end

        `git submodule add #{another_submodule} another-sub-repo 2>&1 > #{File::NULL}`
      end

      it { should be_empty }
    end

    context 'when there is one submodule removal staged' do
      before do
        `git rm sub-repo`
      end

      it 'returns the submodule that was removed' do
        subject.size.should == 1
        subject.first.tap do |sub|
          sub.path.should == 'sub-repo'
          File.directory?(sub.url).should == true
        end
      end
    end

    context 'when there are multiple submodule removals staged' do
      before do
        another_submodule = repo do
          `git commit --allow-empty -m "Another submodule"`
        end

        `git submodule add #{another_submodule} yet-another-sub-repo 2>&1 > #{File::NULL}`
        `git commit -m "Add yet another submodule"`
        `git rm sub-repo`
        `git rm yet-another-sub-repo`
      end

      it 'returns all submodules that were removed' do
        subject.size.should == 2
        subject.map(&:path).sort.should == ['sub-repo', 'yet-another-sub-repo']
      end
    end
  end

  describe '.branches_containing_commit' do
    subject { described_class.branches_containing_commit(commit_ref) }

    around do |example|
      repo do
        `git checkout -b master > #{File::NULL} 2>&1`
        `git commit --allow-empty -m "Initial commit"`
        `git checkout -b topic > #{File::NULL} 2>&1`
        `git commit --allow-empty -m "Another commit"`
        example.run
      end
    end

    context 'when only one branch contains the commit' do
      let(:commit_ref) { 'topic' }

      it 'should return only that branch' do
        subject.size.should == 1
        subject[0].should == 'topic'
      end
    end

    context 'when more than one branch contains the commit' do
      let(:commit_ref) { 'master' }

      it 'should return all branches containing the commit' do
        subject.size.should == 2
        subject.sort.should == %w[master topic]
      end
    end

    context 'when no branches contain the commit' do
      let(:commit_ref) { 'HEAD' }

      before do
        `git checkout --detach > #{File::NULL} 2>&1`
        `git commit --allow-empty -m "Detached HEAD"`
      end

      it { should be_empty }
    end
  end
end
