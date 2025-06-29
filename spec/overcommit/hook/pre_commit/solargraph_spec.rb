# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::Solargraph do
  let(:config) do
    Overcommit::ConfigurationLoader.default_configuration.merge(
      Overcommit::Configuration.new(
        'PreCommit' => {
          'Solargraph' => {
            'problem_on_unmodified_line' => problem_on_unmodified_line
          }
        }
      )
    )
  end
  let(:problem_on_unmodified_line) { 'ignore' }
  let(:context) { double('context') }
  let(:messages) { subject.run }
  let(:result) { double('result') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.rb file2.rb])
    result.stub(:stderr).and_return(stderr)
    result.stub(:stdout).and_return(stdout)
  end

  context 'when Solargraph exits successfully' do
    before do
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    context 'and it printed a message to stderr' do
      let(:stderr) { 'stderr unexpected message that must be fine since command successful' }
      let(:stdout) { '' }
      it { should pass }
    end

    context 'and it printed a message to stdout' do
      let(:stderr) { '' }
      let(:stdout) { 'stdout message that must be fine since command successful' }
      it { should pass }
    end
  end

  context 'when Solargraph exits unsucessfully' do
    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports typechecking issues' do
      let(:stdout) do
        normalize_indent(<<-MSG)
          /home/username/src/solargraph-rails/file1.rb:36 - Unresolved constant Solargraph::Parser::Legacy::NodeChainer
          /home/username/src/solargraph-rails/file2.rb:44 - Unresolved call to []
          /home/username/src/solargraph-rails/file2.rb:99 - Unresolved call to []
          Typecheck finished in 8.921023999806494 seconds.
          189 problems found in 14 of 16 files.
        MSG
      end

      ['', 'unexpected output'].each do |stderr_string|
        context "with stderr output of #{stderr_string.inspect}" do
          let(:stderr) { stderr_string }

          it { should fail_hook }
          it 'reports only three errors and assumes stderr is harmless' do
            expect(messages.size).to eq 3
          end
          it 'parses filename' do
            expect(messages.first.file).to eq '/home/username/src/solargraph-rails/file1.rb'
          end
          it 'parses line number of messages' do
            expect(messages.first.line).to eq 36
          end
          it 'parses and returns error message content' do
            msg = '/home/username/src/solargraph-rails/file1.rb:36 - Unresolved constant Solargraph::Parser::Legacy::NodeChainer'
            expect(messages.first.content).to eq msg
          end
        end
      end
    end

    context 'but it reports no typechecking issues' do
      let(:stdout) do
        normalize_indent(<<-MSG)
           Typecheck finished in 8.095239999704063 seconds.
           0 problems found in 0 of 16 files.
        MSG
      end

      context 'with no stderr output' do
        let(:stderr) { '' }
        it 'should return no messages' do
          expect(messages).to eq([:fail, 'Solargraph failed to run'])
        end
      end

      context 'with stderr output' do
        let(:stderr) { 'something' }
        it 'should raise' do
          expect { messages }.to raise_error(Overcommit::Exceptions::MessageProcessingError)
        end
      end
    end
  end
end
