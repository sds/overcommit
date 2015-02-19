require 'spec_helper'

describe Overcommit::Hook::PostCommit::GitGuilt do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  context 'when git-guilt exits with no output' do
    before do
      result = double('result')
      result.stub(:stdout).and_return('')
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when git-guilt exits with output' do
    before do
      result = double('result')
      result.stub(:stdout).and_return('Overcommit Tester +++')
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end
end
