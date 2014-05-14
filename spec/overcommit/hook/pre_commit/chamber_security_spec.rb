require 'spec_helper'

describe Overcommit::Hook::PreCommit::ChamberSecurity do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject       { described_class.new(config, context) }

  before do
    subject.stub(:in_path?).and_return(true)
    subject.stub(:applicable_files).and_return(['my_settings.yml'])
  end

  context 'when chamber is not installed' do
    before do
      subject.stub(:in_path?).and_return(false)
    end

    it { should warn }
  end

  context 'when chamber exits successfully' do
    before do
      result = double('result')
      result.stub(:stdout).and_return('')
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when chamber exits unsucessfully' do
    before do
      result = double('result')
      result.stub(:stdout).and_return('Some error message')
      subject.stub(:execute).and_return(result)
    end

    it { should fail_hook }
  end
end
