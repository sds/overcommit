require 'spec_helper'

describe Overcommit::Hook::PreCommit::TravisLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:in_path?).and_return(true)
    subject.stub(:applicable_files).and_return(['.travis.yml'])
  end

  context 'when travis-lint is not installed' do
    before do
      subject.stub(:in_path?).and_return(false)
    end

    it { should warn }
  end

  context 'when travis-lint exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when travis-lint exits unsucessfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(false)
      result.stub(:stdout).and_return('Some error message')
      subject.stub(:execute).and_return(result)
    end

    it { should fail_check 'Some error message' }
  end
end
