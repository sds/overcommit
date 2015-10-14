require 'spec_helper'
require 'overcommit/hook_context/commit_msg'

describe Overcommit::HookContext::CommitMsg do
  let(:comment_char) { '#' }
  let(:config) { double('config') }
  let(:args) { [commit_message_file] }
  let(:input) { double('input') }
  let(:context) { described_class.new(config, args, input) }
  before do
    Overcommit::GitConfig.stub(:comment_character).and_return(comment_char)
  end
  let(:commit_msg) do
    [
      '# Please enter the commit message for your changes.',
      'Some commit message',
      '# On branch master',
      'diff --git a/file b/file',
      'index 4ae1030..342a117 100644',
      '--- a/file',
      '+++ b/file',
    ]
  end

  let(:commit_message_file) do
    Tempfile.new('commit-message').tap do |file|
      file.write(commit_msg.join("\n"))
      file.fsync
    end.path
  end

  describe '#commit_message' do
    subject { context.commit_message }

    it 'strips comments and trailing diff' do
      subject.should == "Some commit message\n"
    end

    context 'with alternate comment character' do
      let(:comment_char) { '!' }
      let(:commit_msg) do
        [
          '! Please enter the commit message for your changes.',
          'Some commit message',
          '! On branch master',
          'diff --git a/file b/file',
          'index 4ae1030..342a117 100644',
          '--- a/file',
          '+++ b/file',
        ]
      end

      it 'strips comments and trailing diff' do
        subject.should == "Some commit message\n"
      end
    end
  end

  describe '#commit_message_lines' do
    subject { context.commit_message_lines }

    it 'strips comments and trailing diff' do
      subject.should == ["Some commit message\n"]
    end
  end

  describe '#empty_message?' do
    subject { context.empty_message? }

    context 'when commit message is empty' do
      let(:commit_msg) { [] }

      it { should == true }
    end

    context 'when commit message contains only whitespace' do
      let(:commit_msg) { [' '] }

      it { should == true }
    end

    context 'when commit message is not empty' do
      let(:commit_msg) { ['Some commit message'] }

      it { should == false }
    end
  end
end
