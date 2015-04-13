require 'spec_helper'

describe Overcommit::Hook::PreCommit::Vint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  let(:result) { double('result') }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.vim file2.vim])
    subject.stub(:execute).and_return(result)
  end

  context 'when vint exits successfully' do
    before do
      result.stub(:success?).and_return(true)
    end

    it { should pass }
  end

  context 'when vint exits unsucessfully' do
    before do
      result.stub(:success?).and_return(false)
    end

    context 'and it reports an error' do
      before do
        result.stub(stderr: '', stdout: [
          'file1.vim:1:0: autocmd should execute in augroup or execute with a group',
        ].join("\n"))
      end

      it { should fail_hook }
    end

    context 'with a runtime error' do
      before do
        result.stub(:stderr).and_return([
          'vint ERROR: no such file or directory: `foo.vim`'
        ].join("\n"))
      end

      it { should fail_hook }
    end
  end
end
