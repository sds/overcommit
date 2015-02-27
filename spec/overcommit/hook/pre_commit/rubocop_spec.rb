require 'spec_helper'

describe Overcommit::Hook::PreCommit::Rubocop do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.rb file2.rb])
  end

  context 'when rubocop exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when rubocop exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports a warning' do
      before do
        result.stub(:stdout).and_return([
          'file1.rb:1:1: W: Useless assignment to variable - my_var.',
        ].join("\n"))
        result.stub(:stderr).and_return('')
      end

      it { should warn }
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return([
          'file1.rb:1:1: C: Missing top-level class documentation',
        ].join("\n"))
        result.stub(:stderr).and_return('')
      end

      it { should fail_hook }
    end
  end
end
