# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::PhpCs do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[sample.php])
  end

  context 'when phpcs exits successfully' do
    before do
      sample_output = [
        'File,Line,Column,Type,Message,Source,Severity,Fixable',
        ''
      ].join("\n")

      result = double('result')
      result.stub(:success?).and_return(true)
      result.stub(:stdout).and_return(sample_output)
      result.stub(:status).and_return(0)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when phpcs exits unsuccessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      result.stub(:status).and_return(2)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports a warning' do
      before do
        # rubocop:disable Layout/LineLength
        sample_output = [
          'File,Line,Column,Type,Message,Source,Severity,Fixable',
          '"/Users/craig/HelpScout/overcommit-testing/invalid.php",5,1,warning,"Possible parse error: FOREACH has no AS statement",Squiz.ControlStructures.ForEachLoopDeclaration.MissingAs,5,0'
        ].join("\n")
        # rubocop:enable Layout/LineLength
        result.stub(:stdout).and_return(sample_output)
      end

      it { should warn }
    end

    context 'and it reports an error' do
      before do
        # rubocop:disable Layout/LineLength
        sample_output = [
          'File,Line,Column,Type,Message,Source,Severity,Fixable',
          '"/Users/craig/HelpScout/overcommit-testing/invalid.php",5,1,error,"Inline control structures are not allowed",Generic.ControlStructures.InlineControlStructure.NotAllowed,5,1'
        ].join("\n")
        # rubocop:enable Layout/LineLength
        result.stub(:stdout).and_return(sample_output)
      end

      it { should fail_hook }
    end
  end
end
