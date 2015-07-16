require 'spec_helper'

describe Overcommit::Hook::PreCommit::PuppetLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.pp file2.pp])
  end

  context 'when puppet-lint exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    context 'with no output' do
      before do
        result.stub(:stdout).and_return('')
      end

      it { should pass }
    end

    context 'and it reports a warning' do
      before do
        result.stub(:stdout).and_return(normalize_indent(<<-OUT))
          file1.pp:2:10:WARNING: selector inside resource block (selector_inside_resource)'
        OUT
      end

      it { should warn }
    end
  end

  context 'when puppet-lint exits unsuccessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports a warning' do
      before do
        result.stub(:stdout).and_return(normalize_indent(<<-OUT))
          file1.pp:2:10:WARNING: selector inside resource block (selector_inside_resource)'
        OUT
      end

      it { should warn }
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return(normalize_indent(<<-OUT))
          file1.pp:2:10:ERROR: trailing whitespace (trailing_whitespace)'
        OUT
      end

      it { should fail_hook }
    end
  end
end
