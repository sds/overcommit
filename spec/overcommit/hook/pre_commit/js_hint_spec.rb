require 'spec_helper'

describe Overcommit::Hook::PreCommit::JsHint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.js file2.js])
  end

  context 'when jshint exits successfully' do
    before do
      result = double('result')
      result.stub(success?: true, stdout: '')
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when jshint exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports a warning' do
      before do
        result.stub(:stdout).and_return([
          'file1.js: line 1, col 0, Missing semicolon. (W033)',
          '',
          '1 error'
        ].join("\n"))
      end

      it { should warn }
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return([
          'file1.js: line 1, col 0, Missing "use strict" statement. (E007)',
          '',
          '1 error'
        ].join("\n"))
      end

      it { should fail_hook }
    end
  end
end
