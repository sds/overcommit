require 'spec_helper'

describe Overcommit::Hook::PreCommit::GoLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.go file2.go])
  end

  context 'when golint exits successfully' do
    let(:result) { double('result') }

    before do
      subject.stub(:execute).and_return(result)
    end

    context 'with no output' do
      before do
        result.stub(:stdout).and_return('')
      end

      it { should pass }
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return([
          'file1.go:1:1: error should be the last type when returning multiple items'
        ].join("\n"))
      end

      it { should fail_hook }
    end
  end
end
