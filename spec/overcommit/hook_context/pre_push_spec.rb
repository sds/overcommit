require 'spec_helper'
require 'overcommit/hook_context/pre_push'

describe Overcommit::HookContext::PrePush do
  let(:config) { double('config') }
  let(:args) { [remote_name, remote_url] }
  let(:remote_name) { 'origin' }
  let(:remote_url) { 'git@github.com:brigade/overcommit.git' }
  let(:context) { described_class.new(config, args) }

  describe '#remote_name' do
    subject { context.remote_name }

    it { should == remote_name }
  end

  describe '#remote_url' do
    subject { context.remote_url }

    it { should == remote_url }
  end

  describe '#pushed_commits' do
    subject(:pushed_commits) { context.pushed_commits }

    let(:local_ref) { 'refs/heads/master' }
    let(:local_sha1) { random_hash }
    let(:remote_ref) { 'refs/heads/master' }
    let(:remote_sha1) { random_hash }

    before do
      ARGF.stub(:read).and_return([
        "#{local_ref} #{local_sha1} #{remote_ref} #{remote_sha1}"
      ].join("\n"))
    end

    it 'should parse commit info from the input' do
      pushed_commits.length.should == 1
      pushed_commits.each do |pushed_commit|
        pushed_commit.local_ref.should == local_ref
        pushed_commit.local_sha1.should == local_sha1
        pushed_commit.remote_ref.should == remote_ref
        pushed_commit.remote_sha1.should == remote_sha1
      end
    end
  end
end
