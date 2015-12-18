require 'spec_helper'

describe Overcommit::Hook::PreCommit::RailsBestPractices do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  context 'when rails_best_practices exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when rails_best_practices exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return([
          'file1.rb:7 - simplify render in controllers',
        ].join("\n"))
        result.stub(:stderr).and_return('')
      end

      it { should fail_hook }
    end

    context 'when there is an error running rails_best_practices' do
      before do
        result.stub(:stdout).and_return('')
        result.stub(:stderr).and_return([
          'Something went wrong with rails_best_practices'
        ].join("\n"))
      end

      it { should fail_hook }
    end
  end
end
