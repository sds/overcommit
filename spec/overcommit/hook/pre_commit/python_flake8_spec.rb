require 'spec_helper'

describe Overcommit::Hook::PreCommit::PythonFlake8 do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  let(:subject) { described_class.new(config, context) }

  before do
    subject.stub(:in_path?).and_return(true)
    subject.stub(:applicable_files).and_return(%w[file1.py file2.py])
  end

  context 'when flake8 is not installed' do
    before do
      subject.stub(:in_path?).and_return(false)
    end

    it { should warn }
  end

  context 'when flake8 exits successfully' do
    before do
      result = mock('result')
      result.stub(:success?).and_return(true)
      result.stub(:stdout)
      subject.stub(:command).and_return(result)
    end

    it { should pass }
  end

  context 'when scss-lint exits unsucessfully' do
    before do
      result = mock('result')
      result.stub(:success?).and_return(false)
      result.stub(:stdout)
      subject.stub(:command).and_return(result)
    end

    it { should fail_check }
  end
end
