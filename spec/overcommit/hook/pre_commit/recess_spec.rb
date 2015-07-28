require 'spec_helper'

describe Overcommit::Hook::PreCommit::Recess do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  let(:result) { double('result') }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.css file2.css])
    subject.stub(:execute).and_return(result)
  end

  context 'when recess exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
    end

    context 'with no errors' do
      before do
        result.stub(:stdout).and_return(normalize_indent(<<-OUT))
          FILE: file1.css
          STATUS: Perfect!
        OUT
      end

      it { should pass }
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return(normalize_indent(<<-OUT))
          file1.css:1:Element selectors should not be overqualified
        OUT
      end

      it { should fail_hook }
    end
  end
end
