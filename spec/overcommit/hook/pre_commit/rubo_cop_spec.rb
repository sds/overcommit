require 'spec_helper'

describe Overcommit::Hook::PreCommit::RuboCop do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.rb file2.rb])
  end

  context 'when rubocop exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(success?: true, stderr: '', stdout: '')
      subject.stub(:execute).and_return(result)
    end

    it { should pass }

    context 'and it printed warnings to stderr' do
      before do
        result.stub(:stderr).and_return(normalize_indent(<<-MSG))
          warning: parser/current is loading parser/ruby21, which recognizes
          warning: 2.1.8-compliant syntax, but you are running 2.1.1.
          warning: please see https://github.com/whitequark/parser#compatibility-with-ruby-mri.
        MSG
      end

      it { should pass }
    end
  end

  context 'when rubocop exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports a warning' do
      before do
        result.stub(:stdout).and_return([
          'file1.rb:1:1: W: Useless assignment to variable - my_var.',
        ].join("\n"))
        result.stub(:stderr).and_return('')
      end

      it { should warn }

      context 'and it printed warnings to stderr' do
        before do
          result.stub(:stderr).and_return(normalize_indent(<<-MSG))
            warning: parser/current is loading parser/ruby21, which recognizes
            warning: 2.1.8-compliant syntax, but you are running 2.1.1.
            warning: please see https://github.com/whitequark/parser#compatibility-with-ruby-mri.
          MSG
        end

        it { should warn }
      end
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return([
          'file1.rb:1:1: C: Missing top-level class documentation',
        ].join("\n"))
        result.stub(:stderr).and_return('')
      end

      it { should fail_hook }

      context 'and it printed warnings to stderr' do
        before do
          result.stub(:stderr).and_return(normalize_indent(<<-MSG))
            warning: parser/current is loading parser/ruby21, which recognizes
            warning: 2.1.8-compliant syntax, but you are running 2.1.1.
            warning: please see https://github.com/whitequark/parser#compatibility-with-ruby-mri.
          MSG
        end

        it { should fail_hook }
      end
    end

    context 'when a generic error message is written to stderr' do
      before do
        result.stub(:stdout).and_return('')
        result.stub(:stderr).and_return([
          'Could not find rubocop in any of the sources'
        ].join("\n"))
      end

      it { should fail_hook }
    end
  end
end
