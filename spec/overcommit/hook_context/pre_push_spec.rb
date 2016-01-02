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

  describe '#pushed_refs' do
    subject(:pushed_refs) { context.pushed_refs }

    let(:local_ref) { 'refs/heads/master' }
    let(:local_sha1) { random_hash }
    let(:remote_ref) { 'refs/heads/master' }
    let(:remote_sha1) { random_hash }

    before do
      input.stub(:read).and_return("#{local_ref} #{local_sha1} #{remote_ref} #{remote_sha1}\n")
    end

    it 'should parse commit info from the input' do
      pushed_refs.length.should == 1
      pushed_refs.each do |pushed_ref|
        pushed_ref.local_ref.should == local_ref
        pushed_ref.local_sha1.should == local_sha1
        pushed_ref.remote_ref.should == remote_ref
        pushed_ref.remote_sha1.should == remote_sha1
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
