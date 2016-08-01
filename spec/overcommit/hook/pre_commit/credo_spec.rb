require 'spec_helper'

describe Overcommit::Hook::PreCommit::Credo do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.ex file2.exs])
  end

  context 'when credo exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when credo exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return([
          'file1.ex:1:11: R: Modules should have a @moduledoc tag.',
          'file2.ex:1:11: R: Modules should have a @moduledoc tag.'
        ].join("\n"))
        result.stub(:stderr).and_return('')
      end

      it { should fail_hook }
    end
  end
end
