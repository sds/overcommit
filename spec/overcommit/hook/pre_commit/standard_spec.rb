require 'spec_helper'

describe Overcommit::Hook::PreCommit::Standard do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.js file2.js])
  end

  context 'when standard exits successfully' do
    before do
      result = double('result')
      result.stub(success?: true, stdout: '')
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when standard exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return([
          'standard: Use JavaScript Standard Style (https://github.com/feross/standard)',
          '  file1.js:1:1: Extra semicolon. (eslint/semi)'
        ].join("\n"))
      end

      it { should fail_hook }
    end
  end
end
