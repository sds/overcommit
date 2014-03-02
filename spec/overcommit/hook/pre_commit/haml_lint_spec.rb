require 'spec_helper'

describe Overcommit::Hook::PreCommit::HamlLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  let(:staged_file) { 'filename.haml' }
  let(:applicable_files) { [staged_file, 'file2.haml'] }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:in_path?).and_return(true)
    subject.stub(:applicable_files).and_return(applicable_files)
  end

  context 'when haml-lint is not installed' do
    before do
      subject.stub(:in_path?).and_return(false)
    end

    it { should warn }
  end

  context 'RubyScript should be excluded' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:command).and_return(result)
    end

    it 'should run the right command' do
      expect(subject)
        .to receive(:command)
        .with("haml-lint --exclude-lint RubyScript #{applicable_files.join(' ')}")

      expect(subject).to_not warn
    end
  end

  context 'when haml-lint exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:command).and_return(result)
    end

    it { should pass }
  end

  context 'when haml-lint exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:command).and_return(result)
    end

    context 'and it reports lines that were not modified by the commit' do
      before do
        result.stub(:stdout).and_return([
          'file1.haml:1 [W] Prefer single quoted strings',
        ].join("\n"))

        subject.stub(:modified_lines).and_return([2, 3])
      end

      it { should warn }
    end

    context 'and it reports lines that were modified by the commit' do
      before do
        result.stub(:stdout).and_return([
          'file1.haml:1 [W] Prefer single quoted strings',
        ].join("\n"))

        subject.stub(:modified_lines).and_return([1, 2])
      end

      it { should fail_check }
    end
  end
end
