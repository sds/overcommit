require 'spec_helper'

describe Overcommit::Hook::PreCommit::ChamberVerification do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject       { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(['my_settings.yml'])
  end

  context 'when chamber exits successfully' do
    before do
      result = double('result')
      result.stub(:stdout).and_return('')
      result.stub(:stderr).and_return('')
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when chamber exits unsuccessfully but because of missing keys' do
    before do
      result = double('result')
      result.stub(:stdout).and_return('')
      result.stub(:stderr).and_return('no signature key was found')
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when chamber exits unsucessfully via standard out' do
    before do
      result = double('result')
      result.stub(:stdout).and_return('Some error message')
      result.stub(:stderr).and_return('')
      subject.stub(:execute).and_return(result)
    end

    it { should warn }
  end

  context 'when chamber exits unsucessfully via standard error' do
    before do
      result = double('result')
      result.stub(:stdout).and_return('')
      result.stub(:stderr).and_return('Some error message')
      subject.stub(:execute).and_return(result)
    end

    it { should warn }
  end
end
