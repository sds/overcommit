require 'spec_helper'

describe Overcommit::Hook::PreCommit::Brakeman do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject       { described_class.new(config, context) }

  before do
    subject.stub(:in_path?).and_return(true)
    subject.stub(:applicable_files).and_return(['my_class.rb'])
  end

  context 'when brakeman is not installed' do
    before do
      subject.stub(:in_path?).and_return(false)
    end

    it { should warn }
  end

  context 'when brakeman exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when brakeman exits unsucessfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(false)
      result.stub(:stdout).and_return('Some error message')
      subject.stub(:execute).and_return(result)
    end

    it { should fail_hook 'Some error message' }
  end
end
