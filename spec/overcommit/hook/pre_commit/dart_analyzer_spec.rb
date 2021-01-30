# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::DartAnalyzer do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.dart file2.dart])
  end

  context 'when dartanalyzer exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when dartanalyzer exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return([
          'Analyzing file1.dart...',
          'error • message_ommitted • lib/file1.dart:35:3 • rule',
          'Analyzing file2.dart...',
          'hint • message_ommitted • lib/file2.dart:100:13 • rule',
          'info • message_ommitted • lib/file2.dart:113:16 • rule',
          '3 lints found.'
        ].join("\n"))
      end

      it { should fail_hook }
    end
  end
end
