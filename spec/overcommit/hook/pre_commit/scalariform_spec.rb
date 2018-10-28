# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::Scalariform do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.scala file2.scala])
  end

  context 'when there were no failures or errors' do
    let(:result) { double('result') }

    before do
      subject.stub(:execute).and_return(result)
      result.stub(:stdout).and_return([
        'Assuming source is Scala 2.10.4',
        'Formatting with default preferences.',
        '[OK]     file1.scala',
        '[OK]     file2.scala'
      ].join("\n"))
    end

    it { should pass }
  end

  context 'when there were failures' do
    let(:result) { double('result') }

    before do
      subject.stub(:execute).and_return(result)
      result.stub(:stdout).and_return([
        'Assuming source is Scala 2.10.4',
        'Formatting with default preferences.',
        '[OK]     file1.scala',
        '[FAILED] file2.scala'
      ].join("\n"))
    end

    it { should warn }
  end

  context 'when there were errors' do
    let(:result) { double('result') }

    before do
      subject.stub(:execute).and_return(result)
      result.stub(:stdout).and_return([
        'Assuming source is Scala 2.10.4',
        'Formatting with default preferences.',
        '[ERROR]  file1.scala',
        '[OK]     file2.scala'
      ].join("\n"))
    end

    it { should fail_hook }
  end
end
