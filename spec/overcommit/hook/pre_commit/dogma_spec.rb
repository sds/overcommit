require 'spec_helper'

describe Overcommit::Hook::PreCommit::Dogma do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.ex file2.exs])
  end

  context 'when dogma exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when dogma exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return([
          '27 files, 3 errors!',
          '',
          '== test/support/model_case.ex ==',
          '47: LineLength: Line length should not exceed 80 chars (was 85).',
          '',
          '== test/test_helper.exs ==',
          '6: TrailingBlankLines: Blank lines detected at end of file',
          '5: TrailingWhitespace: Trailing whitespace detected',
          '',
        ].join("\n"))
        result.stub(:stderr).and_return('')
      end

      it { should fail_hook }
    end
  end
end
