require 'spec_helper'

describe Overcommit::Hook::PreCommit::ScssLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.scss file2.scss])
  end

  context 'when scss-lint exits successfully' do
    before do
      result = double('result')
      result.stub(:status).and_return(0)
      result.stub(:stdout).and_return('')
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when scss-lint exits unsucessfully' do
    let(:result) { double('result') }

    before do
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports a warning' do
      before do
        result.stub(:status).and_return(1)
        result.stub(:stdout).and_return([
          'file1.scss:1 [W] Prefer single quoted strings',
        ].join("\n"))
      end

      it { should warn }
    end

    context 'and it reports an error' do
      before do
        result.stub(:status).and_return(2)
        result.stub(:stdout).and_return([
          'file1.scss:1 [E] Syntax Error: Invalid CSS',
        ].join("\n"))
      end

      it { should fail_hook }
    end

    context 'and it returns status code indicating all files were filtered' do
      before do
        result.stub(:status).and_return(81)
        result.stub(:stdout).and_return('')
      end

      it { should pass }
    end
  end
end
