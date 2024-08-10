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
end
