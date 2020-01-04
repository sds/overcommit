# frozen_string_literal: true

require 'spec_helper'
require 'overcommit/hook_context/pre_push'

describe Overcommit::HookContext::PrePush do
  let(:config) { double('config') }
  let(:args) { [remote_name, remote_url] }
  let(:input) { double('input') }
  let(:remote_name) { 'origin' }
  let(:remote_url) { 'git@github.com:brigade/overcommit.git' }
  let(:context) { described_class.new(config, args, input) }

  describe '#remote_name' do
    subject { context.remote_name }

    it { should == remote_name }
  end

  describe '#remote_url' do
    subject { context.remote_url }

    it { should == remote_url }
  end

  describe '#remote_ref_deletion?' do
    subject { context.remote_ref_deletion? }

    let(:standard_input) { "#{local_ref} #{local_sha1} #{remote_ref} #{remote_sha1}\n" }

    before do
      input.stub(:read).and_return(standard_input)
    end

    context 'when pushing new branch to remote ref' do
      let(:local_ref) { 'refs/heads/test' }
      let(:local_sha1) { '' }
      let(:remote_ref) { 'refs/heads/test' }
      let(:remote_sha1) { '0' * 40 }

      it { should == false }
    end

    context 'when pushing update to remote ref' do
      let(:local_ref) { 'refs/heads/test' }
      let(:local_sha1) { '' }
      let(:remote_ref) { 'refs/heads/test' }
      let(:remote_sha1) { random_hash }

      it { should == false }
    end

    context 'when deleting remote ref' do
      let(:local_ref) { '(deleted)' }
      let(:local_sha1) { '' }
      let(:remote_ref) { 'refs/heads/test' }
      let(:remote_sha1) { random_hash }

      it { should == true }
    end

    context 'when no standard input is provided' do
      let(:standard_input) { '' }

      it { should == false }
    end
  end

  describe '#pushed_refs' do
    subject(:pushed_refs) { context.pushed_refs }

    let(:local_ref) { 'refs/heads/master' }
    let(:local_sha1) { random_hash }
    let(:remote_ref) { 'refs/heads/master' }
    let(:remote_sha1) { random_hash }

    before do
      input.stub(:read).and_return("#{local_ref} #{local_sha1} #{remote_ref} #{remote_sha1}\n")
    end

    it 'parses commit info from the input' do
      pushed_refs.length.should == 1
      pushed_refs.each do |pushed_ref|
        pushed_ref.local_ref.should == local_ref
        pushed_ref.local_sha1.should == local_sha1
        pushed_ref.remote_ref.should == remote_ref
        pushed_ref.remote_sha1.should == remote_sha1
      end
    end
  end

  describe '#modified_files' do
    subject { context.modified_files }

    let(:remote_repo) do
      repo do
        touch 'update-me'
        echo 'update', 'update-me'
        touch 'delete-me'
        echo 'delete', 'delete-me'
        `git add . 2>&1 > #{File::NULL}`
        `git commit -m "Initial commit" 2>&1 > #{File::NULL}`
      end
    end

    context 'when current branch has tracking branch' do
      let(:local_ref) { 'refs/heads/project-branch' }
      let(:local_sha1) { get_sha1(local_ref) }
      let(:remote_ref) { 'refs/remotes/origin/master' }
      let(:remote_sha1) { get_sha1(remote_ref) }
      let(:input) do
        double('input', read: "#{local_ref} #{local_sha1} #{remote_ref} #{remote_sha1}\n")
      end

      it 'has modified files based on tracking branch' do
        repo do
          `git remote add origin file://#{remote_repo}`
          `git fetch origin 2>&1 > #{File::NULL} && git reset --hard origin/master`

          `git checkout -b project-branch 2>&1 > #{File::NULL}`
          `git push -u origin project-branch 2>&1 > #{File::NULL}`

          touch 'added-1'
          echo 'add', 'added-1'
          echo 'append', 'update-me'
          FileUtils.rm 'delete-me'
          `git add . 2>&1 > #{File::NULL}`
          `git commit -m "Update Branch 1" 2>&1 > #{File::NULL}`

          touch 'added-2'
          echo 'add', 'added-2'
          `git add . 2>&1 > #{File::NULL}`
          `git commit -m "Update Branch 2" 2>&1 > #{File::NULL}`

          should == %w[added-1 added-2 update-me].map { |file| File.expand_path(file) }
          should_not include(*%w[delete-me].map { |file| File.expand_path(file) })
        end
      end
    end

    context 'when pushing multiple branches at once' do
      let(:local_ref_1) { 'refs/heads/project-branch-1' }
      let(:local_sha1_1) { get_sha1(local_ref_1) }
      let(:local_ref_2) { 'refs/heads/project-branch-2' }
      let(:local_sha1_2) { get_sha1(local_ref_2) }
      let(:remote_ref) { 'refs/remotes/origin/master' }
      let(:remote_sha1) { get_sha1(remote_ref) }
      let(:input) do
        double('input', read: ref_ranges)
      end
      let(:ref_ranges) do
        [
          "#{local_ref_1} #{local_sha1_1} #{remote_ref} #{remote_sha1}\n",
          "#{local_ref_2} #{local_sha1_2} #{remote_ref} #{remote_sha1}\n"
        ].join
      end

      it 'has modified files based on multiple tracking branches' do
        repo do
          `git remote add origin file://#{remote_repo}`
          `git fetch origin 2>&1 > #{File::NULL} && git reset --hard origin/master`

          `git checkout -b project-branch-1 2>&1 > #{File::NULL}`
          `git push -u origin project-branch-1 2>&1 > #{File::NULL}`

          touch 'added-1'
          echo 'add', 'added-1'
          echo 'append', 'update-me'
          FileUtils.rm 'delete-me'
          `git add . 2>&1 > #{File::NULL}`
          `git commit -m "Update Branch 1" 2>&1 > #{File::NULL}`

          `git checkout master 2>&1 > #{File::NULL}`
          `git checkout -b project-branch-2 2>&1 > #{File::NULL}`
          `git push -u origin project-branch-2 2>&1 > #{File::NULL}`

          echo 'append', 'update-me'
          touch 'added-2'
          echo 'add', 'added-2'
          `git add . 2>&1 > #{File::NULL}`
          `git commit -m "Update Branch 2" 2>&1 > #{File::NULL}`

          should == %w[added-1 update-me added-2].map { |file| File.expand_path(file) }
          should_not include(*%w[delete-me].map { |file| File.expand_path(file) })
        end
      end
    end

    context 'when current branch has no tracking branch' do
      let(:local_ref) { 'refs/heads/project-branch' }
      let(:local_sha1) { get_sha1(local_ref) }
      let(:remote_ref) { 'refs/heads/master' }
      let(:remote_sha1) { get_sha1(remote_ref) }
      let(:input) do
        double('input', read: "#{local_ref} #{local_sha1} #{remote_ref} #{remote_sha1}\n")
      end

      it 'has modified files based on parent branch' do
        repo do
          `git remote add origin file://#{remote_repo}`
          `git fetch origin 2>&1 > #{File::NULL} && git reset --hard origin/master`

          `git checkout -b project-branch 2>&1 > #{File::NULL}`

          touch 'added-1'
          echo 'add', 'added-1'
          echo 'append', 'update-me'
          FileUtils.rm 'delete-me'
          `git add . 2>&1 > #{File::NULL}`
          `git commit -m "Update Branch 1" 2>&1 > #{File::NULL}`

          touch 'added-2'
          echo 'add', 'added-2'
          `git add . 2>&1 > #{File::NULL}`
          `git commit -m "Update Branch 2" 2>&1 > #{File::NULL}`

          should == %w[added-1 added-2 update-me].map { |file| File.expand_path(file) }
          should_not include(*%w[delete-me].map { |file| File.expand_path(file) })
        end
      end
    end
  end

  describe '#modified_lines_in_file' do
    subject { context.modified_lines_in_file(file) }
    let(:local_ref_1) { 'refs/heads/project-branch-1' }
    let(:local_sha1_1) { get_sha1(local_ref_1) }
    let(:local_ref_2) { 'refs/heads/project-branch-2' }
    let(:local_sha1_2) { get_sha1(local_ref_2) }
    let(:remote_ref) { 'refs/remotes/origin/master' }
    let(:remote_sha1) { get_sha1(remote_ref) }
    let(:input) do
      double('input', read: ref_ranges)
    end
    let(:ref_ranges) do
      [
        "#{local_ref_1} #{local_sha1_1} #{remote_ref} #{remote_sha1}\n",
        "#{local_ref_2} #{local_sha1_2} #{remote_ref} #{remote_sha1}\n"
      ].join
    end
    let(:remote_repo) do
      repo do
        touch 'initial_file'
        echo 'initial', 'initial_file'
        `git add . 2>&1 > #{File::NULL}`
        `git commit -m "Initial commit" 2>&1 > #{File::NULL}`
      end
    end

    context 'when updating a file' do
      let(:file) { File.expand_path('initial_file') }

      it 'has modified lines in file' do
        repo do
          `git remote add origin file://#{remote_repo}`
          `git fetch origin 2>&1 > #{File::NULL} && git reset --hard origin/master`

          `git checkout -b project-branch-1 2>&1 > #{File::NULL}`
          `git push -u origin project-branch-1 2>&1 > #{File::NULL}`

          echo 'append-1', 'initial_file', append: true

          `git add . 2>&1 > #{File::NULL}`
          `git commit -m "Update Branch 1 Commit 1" 2>&1 > #{File::NULL}`

          echo 'append-2', 'initial_file', append: true

          `git add . 2>&1 > #{File::NULL}`
          `git commit -m "Update Branch 1 Commit 2" 2>&1 > #{File::NULL}`

          `git checkout -b project-branch-2 2>&1 > #{File::NULL}`
          `git push -u origin project-branch-2 2>&1 > #{File::NULL}`

          echo 'append-3', 'initial_file', append: true

          `git add . 2>&1 > #{File::NULL}`
          `git commit -m "Update Branch 2 Commit 1" 2>&1 > #{File::NULL}`

          should == [2, 3, 4].to_set
        end
      end
    end

    context 'when adding a file' do
      let(:file) { File.expand_path('new_file') }

      it 'has modified lines in file' do
        repo do
          `git remote add origin file://#{remote_repo}`
          `git fetch origin 2>&1 > #{File::NULL} && git reset --hard origin/master`

          `git checkout -b project-branch-1 2>&1 > #{File::NULL}`
          `git push -u origin project-branch-1 2>&1 > #{File::NULL}`

          touch 'new_file'

          echo 'append-1', 'new_file', append: true

          `git add . 2>&1 > #{File::NULL}`
          `git commit -m "Update Branch 1 Commit 1" 2>&1 > #{File::NULL}`

          echo 'append-2', 'new_file', append: true

          `git add . 2>&1 > #{File::NULL}`
          `git commit -m "Update Branch 1 Commit 2" 2>&1 > #{File::NULL}`

          `git checkout -b project-branch-2 2>&1 > #{File::NULL}`
          `git push -u origin project-branch-2 2>&1 > #{File::NULL}`

          echo 'append-3', 'new_file', append: true

          `git add . 2>&1 > #{File::NULL}`
          `git commit -m "Update Branch 2 Commit 1" 2>&1 > #{File::NULL}`

          should == [1, 2, 3].to_set
        end
      end
    end

    context 'when deleting a file' do
      let(:file) { File.expand_path('initial_file') }
      let(:ref_ranges) do
        "#{local_ref_1} #{local_sha1_1} #{remote_ref} #{remote_sha1}\n"
      end

      it 'has modified lines in file' do
        repo do
          `git remote add origin file://#{remote_repo}`
          `git fetch origin 2>&1 > #{File::NULL} && git reset --hard origin/master`

          `git checkout -b project-branch-1 2>&1 > #{File::NULL}`
          `git push -u origin project-branch-1 2>&1 > #{File::NULL}`

          FileUtils.rm 'initial_file'

          `git add . 2>&1 > #{File::NULL}`
          `git commit -m "Update Branch 1" 2>&1 > #{File::NULL}`

          should == [].to_set
        end
      end
    end
  end

  describe Overcommit::HookContext::PrePush::PushedRef do
    let(:local_ref) { 'refs/heads/master' }
    let(:remote_ref) { 'refs/heads/master' }
    let(:local_sha1) { random_hash }
    let(:remote_sha1) { random_hash }
    let(:pushed_ref) { described_class.new(local_ref, local_sha1, remote_ref, remote_sha1) }

    describe '#forced?' do
      subject { pushed_ref.forced? }

      context 'when creating a ref' do
        before do
          pushed_ref.stub(created?: true, deleted?: false)
        end

        it { should == false }
      end

      context 'when deleting a ref' do
        before do
          pushed_ref.stub(created?: false, deleted?: true)
        end

        it { should == false }
      end

      context 'when remote commits are not overwritten' do
        before do
          pushed_ref.stub(created?: false,
                          deleted?: false,
                          overwritten_commits: [])
        end

        it { should == false }
      end

      context 'when remote commits are overwritten' do
        before do
          pushed_ref.stub(created?: false,
                          deleted?: false,
                          overwritten_commits: [random_hash])
        end

        it { should == true }
      end

      context 'when remote ref head does not exist locally' do
        let(:git_error_msg) { "fatal: bad object #{remote_sha1}" }

        before do
          pushed_ref.stub(created?: false, deleted?: false)
          result = double(success?: false, stderr: git_error_msg)
          Overcommit::Subprocess.stub(:spawn).and_return(result)
        end

        it 'should raise' do
          expect { subject }.to raise_error(Overcommit::Exceptions::GitRevListError,
                                            /#{git_error_msg}/)
        end
      end
    end

    describe '#created?' do
      subject { pushed_ref.created? }

      context 'when creating a ref' do
        before do
          pushed_ref.stub(:remote_sha1).and_return('0' * 40)
        end

        it { should == true }
      end

      context 'when not creating a ref' do
        before do
          pushed_ref.stub(:remote_sha1).and_return(random_hash)
        end

        it { should == false }
      end
    end

    describe '#deleted?' do
      subject { pushed_ref.deleted? }

      context 'when deleting a ref' do
        before do
          pushed_ref.stub(:local_sha1).and_return('0' * 40)
        end

        it { should == true }
      end

      context 'when not deleting a ref' do
        before do
          pushed_ref.stub(:local_sha1).and_return(random_hash)
        end

        it { should == false }
      end
    end

    describe '#destructive?' do
      subject { pushed_ref.destructive? }

      context 'when deleting a ref' do
        before do
          pushed_ref.stub(:deleted?).and_return(true)
        end

        it { should == true }
      end

      context 'when force-pushing a ref' do
        before do
          pushed_ref.stub(deleted?: false, forced?: true)
        end

        it { should == true }
      end

      context 'when not deleting or force-pushing a ref' do
        before do
          pushed_ref.stub(deleted?: false, forced?: false)
        end

        it { should == false }
      end
    end
  end
end
