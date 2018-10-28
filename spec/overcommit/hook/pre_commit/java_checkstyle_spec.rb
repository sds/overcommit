# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::JavaCheckstyle do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.java file2.java])
  end

  context 'when checkstyle exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    context 'with no errors or warnings' do
      before do
        result.stub(:stdout).and_return([
          'Starting audit...',
          'Audit done.',
        ].join("\n"))
      end

      it { should pass }
    end
  end

  context 'when checkstyle exits unsuccessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports a message with no severity tag' do
      before do
        result.stub(:stdout).and_return([
          'Starting audit...',
          'file1.java:1: Missing a Javadoc comment.',
          'Audit done.'
        ].join("\n"))
      end

      it { should fail_hook }
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return([
          'Starting audit...',
          '[ERROR] file1.java:1: Missing a Javadoc comment.',
          'Audit done.'
        ].join("\n"))
      end

      it { should fail_hook }
    end

    context 'and it reports an warning' do
      before do
        result.stub(:stdout).and_return([
          'Starting audit...',
          '[WARN] file1.java:1: Missing a Javadoc comment.',
          'Audit done.'
        ].join("\n"))
      end

      it { should warn }
    end

    context 'and it reports an info message' do
      before do
        result.stub(:stdout).and_return([
          'Starting audit...',
          '[INFO] file1.java:1: Missing a Javadoc comment.',
          'Audit done.'
        ].join("\n"))
      end

      it { should warn }
    end
  end
end
