# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::GitConfig do
  describe '.comment_character' do
    subject { described_class.comment_character }

    context 'with no configuration' do
      it 'should be "#"' do
        repo do
          `git config --local core.commentchar ""`
          expect(subject).to eq '#'
        end
      end
    end

    context 'with custom configuration' do
      it 'should be the configured character' do
        repo do
          `git config --local core.commentchar x`
          expect(subject).to eq 'x'
        end
      end
    end
  end

  describe '.commit_cleanup_mode' do
    subject { described_class.commit_cleanup_mode }

    let(:command) { 'git commit -m Test' }
    let(:configured_mode) { 'default' }
    let(:editor) { 'editor' }

    before do
      allow(Overcommit::Utils).to receive(:parent_command).and_return(command)
    end

    around do |example|
      repo do
        shell(['git', 'config', '--local', 'commit.cleanup', configured_mode])
        Overcommit::Utils.with_environment('GIT_EDITOR' => editor) { example.run }
      end
    end

    it 'strips comments by default when an editor is used' do
      expect(subject).to eq('strip')
    end

    context 'when Git disables the editor' do
      let(:editor) { ':' }

      it 'preserves comments by default' do
        expect(subject).to eq('whitespace')
      end

      context 'with strip configured' do
        let(:configured_mode) { 'strip' }

        it 'honors the explicit configuration' do
          expect(subject).to eq('strip')
        end
      end
    end

    %w[strip whitespace verbatim scissors].each do |mode|
      context "with #{mode} configured" do
        let(:configured_mode) { mode }

        it 'honors commit.cleanup' do
          expect(subject).to eq(mode)
        end
      end
    end

    context 'with a command-line override' do
      let(:configured_mode) { 'strip' }
      let(:command) { 'git commit --cleanup=whitespace -m Test' }

      it 'gives the flag precedence over configuration' do
        expect(subject).to eq('whitespace')
      end
    end

    context 'with a separate command-line value' do
      let(:command) { 'git commit --cleanup verbatim -m Test' }

      it 'honors the flag' do
        expect(subject).to eq('verbatim')
      end
    end

    context 'with a quoted Windows command-line flag' do
      let(:command) { '"git.exe" "commit" "--cleanup=whitespace" "-m" "Test"' }
      let(:configured_mode) { 'strip' }

      it 'recognizes the quoted override' do
        expect(subject).to eq('whitespace')
      end
    end

    context 'with a quoted separate value' do
      let(:command) { '"git.exe" "commit" "--cleanup" "verbatim" "-m" "Test"' }

      it 'recognizes the quoted override' do
        expect(subject).to eq('verbatim')
      end
    end

    context 'with repeated command-line flags' do
      let(:command) { 'git commit --cleanup=strip --cleanup=whitespace -m Test' }

      it 'uses the last flag, like Git' do
        expect(subject).to eq('whitespace')
      end
    end

    context 'when parent process information is unavailable' do
      let(:command) { nil }
      let(:configured_mode) { 'whitespace' }

      it 'uses configuration' do
        expect(subject).to eq('whitespace')
      end
    end

    context 'when the parent command contains invalid bytes' do
      let(:command) { "git commit --cleanup=whitespace -m \xFF" }

      it 'still recognizes the ASCII option' do
        expect(subject).to eq('whitespace')
      end
    end
  end

  describe '.hooks_path' do
    subject { described_class.hooks_path }

    context 'when not explicitly set' do
      around do |example|
        repo do
          example.run
        end
      end

      it 'returns the default hook path' do
        expect(subject).to eq File.expand_path(File.join('.git', 'hooks'))
      end
    end

    context 'when explicitly set to an empty string' do
      around do |example|
        repo do
          `git config --local core.hooksPath ""`
          example.run
        end
      end

      it 'returns the default hook path' do
        expect(subject).to eq File.expand_path(File.join('.git', 'hooks'))
      end
    end

    context 'when explicitly set to an absolute path' do
      around do |example|
        repo do
          `git config --local core.hooksPath /etc/hooks`
          example.run
        end
      end

      it 'returns the absolute path' do
        expect(subject).to eq File.absolute_path('/etc/hooks')
      end
    end

    context 'when explicitly set to a relative path' do
      around do |example|
        repo do
          `git config --local core.hooksPath my-hooks`
          example.run
        end
      end

      it 'returns the absolute path to the directory relative to the repo root' do
        expect(subject).to eq File.expand_path('my-hooks')
      end
    end

    context 'when explicitly set to a path starting with a tilde' do
      around do |example|
        repo do
          `git config --local core.hooksPath ~/my-hooks`
          example.run
        end
      end

      it 'returns the absolute path to the folder in the users home path' do
        expect(subject).to eq File.expand_path('~/my-hooks')
        expect(subject).not_to include('~')
      end
    end
  end

  describe '.signature_scope' do
    subject { described_class.signature_scope }

    context 'when extensions.worktreeConfig is not set' do
      around do |example|
        repo do
          example.run
        end
      end

      it { should == '--local' }
    end

    context 'when extensions.worktreeConfig is false' do
      around do |example|
        repo do
          `git config --local extensions.worktreeConfig false`
          example.run
        end
      end

      it { should == '--local' }
    end

    context 'when extensions.worktreeConfig is true' do
      around do |example|
        repo do
          `git config --local extensions.worktreeConfig true`
          example.run
        end
      end

      it { should == '--worktree' }
    end
  end
end
