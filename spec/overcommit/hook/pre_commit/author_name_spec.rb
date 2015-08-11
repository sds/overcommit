require 'spec_helper'

describe Overcommit::Hook::PreCommit::AuthorName do
  let(:config) { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }
  let(:result) { double('result') }

  before do
    result.stub(:stdout).and_return(name)
    subject.stub(:execute).and_return(result)
  end

  context 'when user has no name' do
    let(:name) { '' }

    it { should fail_hook }
  end

  context 'when user has only a first name' do
    let(:name) { 'John' }

    it { should fail_hook }
  end

  context 'when user has first and last name' do
    let(:name) { 'John Doe' }

    it { should pass }
  end
end
