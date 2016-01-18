require 'spec_helper'

describe Overcommit::Hook::PreCommit::Mdl do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  let(:result) { double('result') }

  before do
    result.stub(success?: success, stdout: stdout, stderr: stderr)
    subject.stub(:applicable_files).and_return(%w[file1.md file2.md])
    subject.stub(:execute).and_return(result)
  end

  context 'when mdl exits successfully' do
    let(:success) { true }
    let(:stdout) { '' }
    let(:stderr) { '' }

    it { should pass }
  end

  context 'when mdl exits unsuccessfully' do
    let(:success) { false }

    context 'and it reports an error' do
      let(:stdout) { 'file1.md:1: MD013 Line length' }
      let(:stderr) { '' }

      it { should fail_hook }
    end

    context 'when there is an error running mdl' do
      let(:stdout) { '' }
      let(:stderr) { 'Some runtime error' }

      it { should fail_hook }
    end
  end
end
