require 'spec_helper'

describe Overcommit::Hook::PreCommit::CoffeeLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:in_path?).and_return(true)
    subject.stub(:applicable_files).and_return(%w[file1.coffee file2.coffee])
  end

  context 'when coffeelint is not installed' do
    before do
      subject.stub(:in_path?).and_return(false)
    end

    it { should warn }
  end

  context 'when coffeelint exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:command).and_return(result)
    end

    it { should pass }
  end

  context 'when coffeelint exits unsucessfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(false)
      result.stub(:stdout)
      subject.stub(:command).and_return(result)
    end

    it { should fail_check }
  end
end
