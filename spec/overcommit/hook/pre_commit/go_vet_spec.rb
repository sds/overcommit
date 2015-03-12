require 'spec_helper'

describe Overcommit::Hook::PreCommit::GoVet do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.go file2.go])
  end

  context 'when go vet exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when go vet exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'when go tool vet is not installed' do
      before do
        result.stub(stderr:
          'go tool: no such tool "vet"; to install:'
        )
      end

      it { should fail_hook /is not installed/ }
    end

    context 'and it reports an error' do
      before do
        result.stub(stderr:
          'file1.go:1: possible formatting directive in Print call'
        )
      end

      it { should fail_hook /formatting directive/ }
    end
  end
end
