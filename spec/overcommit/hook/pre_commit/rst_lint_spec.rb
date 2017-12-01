require 'spec_helper'

describe Overcommit::Hook::PreCommit::RstLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  let(:result) { double('result') }

  before do
    result.stub(success?: success, stdout: stdout, stderr: stderr)
    subject.stub(:applicable_files).and_return(%w[file1.rst file2.rst])
    subject.stub(:execute).and_return(result)
  end

  context 'when rst-lint exits successfully' do
    let(:success) { true }
    let(:stdout) { '' }
    let(:stderr) { '' }

    it { should pass }
  end

  context 'when rst-lint exits unsuccessfully' do
    let(:success) { false }

    context 'and it reports an error' do
      let(:stdout) { 'WARNING file1.rst:7 Title underline too short.' }
      let(:stderr) { '' }

      it { should fail_hook }
    end

    context 'when there is an error running rst-lint' do
      let(:stdout) { '' }
      let(:stderr) { 'Some runtime error' }

      it { should fail_hook }
    end
  end
end
