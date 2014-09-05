require 'spec_helper'

describe Overcommit::Hook::PreCommit::JsxHint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.js.jsx file2.js.jsx])
  end

  context 'when jsxhint exits with no output' do
    before do
      result = double('result')
      result.stub(:stdout).and_return('')
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when jsxhint exits with output' do
    before do
      result = double('result')
      result.stub(:stdout).and_return('Undefined variable')
      subject.stub(:execute).and_return(result)
    end

    it { should fail_hook }
  end
end
