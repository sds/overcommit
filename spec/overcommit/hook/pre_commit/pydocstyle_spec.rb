require 'spec_helper'

describe Overcommit::Hook::PreCommit::Pydocstyle do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.py file2.py])
  end

  context 'when pydocstyle exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when pydocstyle exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:stderr).and_return([
          'file1.py:1 in public method `foo`:',
          '        D102: Docstring missing'
        ].join("\n"))
      end

      it { should fail_hook }
    end
  end
end
