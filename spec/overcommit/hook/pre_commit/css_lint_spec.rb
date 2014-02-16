require 'spec_helper'

describe Overcommit::Hook::PreCommit::CssLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:in_path?).and_return(true)
    subject.stub(:applicable_files).and_return(%w[file1.css file2.css])
  end

  context 'when csslint is not installed' do
    before do
      subject.stub(:in_path?).and_return(false)
    end

    it { should warn }
  end

  context 'when csslint exits with no output' do
    before do
      result = double('result')
      result.stub(:stdout).and_return('')
      subject.stub(:command).and_return(result)
    end

    it { should pass }
  end

  context 'when csslint exits with output' do
    before do
      result = double('result')
      result.stub(:stdout).and_return('Error - @charset not allowed here')
      subject.stub(:command).and_return(result)
    end

    it { should fail_check }
  end
end
