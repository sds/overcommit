# frozen_string_literal: true

require 'spec_helper'

# Exercise the installed hooks and Git's final message, rather than mocking cleanup.
describe 'commit messages beginning with the comment character' do
  let(:message) { '#16: This is a sample commit for issue 16' }
  let(:commit_args) { [] }
  let(:trailing_args) { [] }
  let(:git_config) { {} }
  let(:config) do
    {
      'PreCommit' => { 'ALL' => { 'enabled' => false } },
      'CommitMsg' => {
        'ALL' => { 'enabled' => false },
        'EmptyMessage' => { 'enabled' => true },
      },
    }
  end

  around do |example|
    repo do
      File.write('.overcommit.yml', config.to_yaml)
      git_config.each { |key, value| shell(['git', 'config', '--local', key, value]) }
      install_overcommit_hooks
      example.run
    end
  end

  subject(:result) do
    Overcommit::Utils.with_environment('OVERCOMMIT_DEBUG' => '1') do
      shell(['git', 'commit', '--allow-empty', *commit_args, '-m', message, *trailing_args])
    end
  end

  shared_examples 'preserves the message' do
    it 'passes EmptyMessage and records the original title' do
      expect(result.status).to eq(0), result.stdout + result.stderr
      expect(shell(%w[git log -1 --format=%B]).stdout.strip).to eq(message)
    end
  end

  include_examples 'preserves the message'

  context 'with an alternate comment character' do
    let(:git_config) { { 'core.commentChar' => ';' } }

    include_examples 'preserves the message'
  end

  context 'with whitespace cleanup configured' do
    let(:git_config) { { 'commit.cleanup' => 'whitespace' } }

    include_examples 'preserves the message'
  end

  context 'with whitespace cleanup on the command line' do
    let(:commit_args) { ['--cleanup=whitespace'] }

    include_examples 'preserves the message'

    context 'overriding strip cleanup in Git configuration' do
      let(:git_config) { { 'commit.cleanup' => 'strip' } }

      include_examples 'preserves the message'
    end
  end

  context 'with a cleanup flag after the message' do
    let(:git_config) { { 'commit.cleanup' => 'strip' } }
    let(:trailing_args) { ['--cleanup=whitespace'] }

    include_examples 'preserves the message'
  end

  context 'with verbatim cleanup' do
    let(:commit_args) { ['--cleanup=verbatim'] }

    include_examples 'preserves the message'
  end

  context 'when editing the message' do
    let(:commit_args) { ['--edit'] }

    around do |example|
      # Use a real editor command, so Git does not set its no-editor ':' marker.
      editor = %{"#{RbConfig.ruby}" -e "exit 0"}
      Overcommit::Utils.with_environment('GIT_EDITOR' => editor) { example.run }
    end

    it 'rejects a title that default cleanup treats as a comment' do
      expect(result.status).not_to eq(0)
      expect(result.stdout + result.stderr).to include('Commit message should not be empty')
    end

    context 'with whitespace cleanup configured' do
      let(:git_config) { { 'commit.cleanup' => 'whitespace' } }

      it 'preserves the comment-prefixed title' do
        expect(result.status).to eq(0), result.stdout + result.stderr
        expect(shell(%w[git log -1 --format=%B]).stdout.lines.first.chomp).to eq(message)
      end
    end

    context 'with a command-line override of strip cleanup' do
      let(:git_config) { { 'commit.cleanup' => 'strip' } }
      let(:commit_args) { ['--edit', '--cleanup=whitespace'] }

      it 'preserves the comment-prefixed title' do
        expect(result.status).to eq(0), result.stdout + result.stderr
        expect(shell(%w[git log -1 --format=%B]).stdout.lines.first.chomp).to eq(message)
      end
    end
  end

  context 'with strip cleanup' do
    let(:commit_args) { ['--cleanup=strip'] }

    it 'rejects a message that becomes empty' do
      expect(result.status).not_to eq(0)
      expect(result.stdout + result.stderr).to include('Commit message should not be empty')
    end
  end

  context 'with an empty message and an alternate comment character' do
    let(:git_config) { { 'core.commentChar' => ';' } }
    let(:message) { '' }

    it 'still rejects the empty message' do
      expect(result.status).not_to eq(0)
      expect(result.stdout + result.stderr).to include('Commit message should not be empty')
    end
  end
end
