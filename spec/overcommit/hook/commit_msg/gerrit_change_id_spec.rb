require 'spec_helper'

describe Overcommit::Hook::CommitMsg::GerritChangeId do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }
  let(:commit_msg_file) { Tempfile.new('commit-msg') }

  before do
    commit_msg_file.write(commit_msg)
    commit_msg_file.close
    context.stub(:commit_message_file).and_return(commit_msg_file.path)
  end

  context 'when the commit message contains no Change-Id' do
    let(:commit_msg) { 'Add code to repo' }

    it { should pass }

    it 'adds a Change-Id to the commit message' do
      subject.run
      File.open(commit_msg_file.path, 'r').read.should =~ /Change-Id/
    end
  end

  context 'when the commit message already contains a Change-Id' do
    let(:commit_msg) { "Add code to repo\n\nChange-Id: I9f2b5528fa20ac91a55bbe9371e76a12dd1cce11" }

    it { should pass }

    it 'does nothing' do
      before = File.open(commit_msg_file.path, 'r').read
      subject.run
      after = File.open(commit_msg_file.path, 'r').read
      before.should == after
    end
  end
end
