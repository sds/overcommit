require 'spec_helper'

describe Overcommit::Hook::PreCommit::GoLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.go file2.go])
  end

  context 'when golint exits successfully' do
    before do
      stdout = double('tempfile')
      stdout.stub(:empty?).and_return(true)

      result = double('result')
      result.stub(:stdout).and_return(stdout)

      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when golint exits with stdout' do
    before do
      stdout = double('tempfile')
      stdout.stub(:empty?).and_return(false)

      result = double('result')
      result.stub(:stdout).and_return(stdout)

      subject.stub(:execute).and_return(result)
    end

    it { should fail_hook }
  end
end
