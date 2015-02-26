require 'spec_helper'

describe Overcommit::Hook::PreCommit::Pyflakes do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.py file2.py])
  end

  context 'when pyflakes exits successfully' do
    before do
      result = double('result')
      result.stub(:success? => true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when pyflakes exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(success?: false, stdout: '', stderr: '')
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports a warning' do
      before do
        result.stub(:stdout).and_return([
          "file1.py:1: local variable 'x' is assigned to but never used"
        ].join("\n"))

        subject.stub(:modified_lines_in_file).and_return([2, 3])
      end

      it { should warn }
    end

    context 'and it reports an error' do
      before do
        result.stub(:stderr).and_return([
          'file1.py:1:1: invalid syntax'
        ].join("\n"))

        subject.stub(:modified_lines_in_file).and_return([1, 2])
      end

      it { should fail_hook }
    end
  end
end
