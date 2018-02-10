require 'spec_helper'

describe Overcommit::Hook::PrePush::PhpUnit do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject       { described_class.new(config, context) }

  context 'when phpunit exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when phpunit exits unsucessfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(false)
      result.stub(:stdout).and_return('Some error message')
      result.stub(:stderr).and_return('')
      subject.stub(:execute).and_return(result)
    end

    it { should fail_hook 'Some error message' }
  end
end
