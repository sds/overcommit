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
end
