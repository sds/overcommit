require 'spec_helper'

describe Overcommit::Hook::PreCommit::MetadataJsonLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  context 'metadata.json not modified' do
    before do
      subject.stub(:applicable_files).and_return(%w[file1.pp file2.pp])
    end

    it { should pass }
  end

  context 'metadata.json is modified' do
    before do
      subject.stub(:applicable_files).and_return(%w[file1.pp file2.pp metadata.json])
    end

    context 'when metadata-json-lint exits successfully' do
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
            (WARN) requirements: The 'pe' requirement is no longer supported by the Forge.
          OUT
        end

        it { should warn }
      end
    end

    context 'when metadata-json-lint exits unsuccessfully' do
      let(:result) { double('result') }

      before do
        result.stub(:success?).and_return(false)
        subject.stub(:execute).and_return(result)
      end

      context 'and it reports a warning' do
        before do
          result.stub(:stdout).and_return(normalize_indent(<<-OUT))
            (WARN) requirements: The 'pe' requirement is no longer supported by the Forge.
          OUT
        end

        it { should warn }
      end

      context 'and it reports an error' do
        before do
          result.stub(:stdout).and_return(normalize_indent(<<-OUT))
            (ERR) requirements: The 'pe' requirement is no longer supported by the Forge.
          OUT
        end

        it { should fail_hook }
      end
    end
  end
end
