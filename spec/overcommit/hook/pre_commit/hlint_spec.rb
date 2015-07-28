require 'spec_helper'

describe Overcommit::Hook::PreCommit::Hlint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  let(:result) { double('result') }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.hs file2.hs])
    subject.stub(:execute).and_return(result)
  end

  context 'when hlint exits successfully' do
    before do
      result.stub(success?: true, stdout: '')
    end

    it { should pass }
  end

  context 'when hlint exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
    end

    context 'and it reports a warning' do
      before do
        result.stub(:stdout).and_return(normalize_indent(<<-OUT))
          file1.hs:22:16: Warning: Use const
          Found:
            \\ _ -> False
          Why not:
            const False
        OUT
      end

      it { should warn }
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return(normalize_indent(<<-OUT))
          file1.hs:22:5: Error: Redundant lambda
          Found:
            nameHack = \\ _ -> Nothing
          Why not:
            nameHack _ = Nothing
        OUT
      end

      it { should fail_hook }
    end
  end
end
