require 'spec_helper'

describe Overcommit::Hook::PreCommit::ShellCheck do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.sh file2.sh])
  end

  context 'when shellcheck exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when shellcheck exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports a note' do
      before do
        result.stub(:stdout).and_return([
          "file1.sh:1:1: note: Use ./*.ogg so names with dashes won't become \
           options. [SC2035]",
        ].join("\n"))
        result.stub(:stderr).and_return('')
      end

      it { should warn }
    end

    context 'and it reports a warning' do
      before do
        result.stub(:stdout).and_return([
          "file1.sh:1:1: warning: Quote the parameter to -name so the shell \
           won't interpret it. [SC2061]",
        ].join("\n"))
        result.stub(:stderr).and_return('')
      end

      it { should fail_hook }
    end
  end
end
