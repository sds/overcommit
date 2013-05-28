require 'spec_helper'
require 'tempfile'

describe Overcommit::GitHook::HookSpecificCheck do
  class SpeccedCheck < described_class
  end

  let(:arguments) { [] }
  subject { SpeccedCheck.new(*arguments) }

  describe '#name' do
    it 'underscorizes' do
      subject.name.should == 'specced_check'
    end
  end

  describe '#stealth?' do
    before do
      @old_stealth = subject.stealth?
    end

    after do
      subject.class.stealth = @old_stealth
    end

    it 'is not stealth by default' do
      subject.stealth?.should be_false
    end

    context 'when marked `stealth!`' do
      it 'returns true' do
        subject.class.stealth!
        subject.should be_stealth
      end
    end
  end

  describe '#commit_message' do
    context 'when passed no arguments' do
      it 'fails' do
        expect { subject.send(:commit_message) }.
          to raise_error
      end
    end

    context 'when passed a filename from the command line' do
      let(:tempfile)  { Tempfile.new('commit-msg-spec') }
      let(:arguments) { [tempfile.path] }
      let(:message)   { 'Hello, World!' }

      before do
        tempfile.write message
        tempfile.rewind
      end

      after do
        tempfile.close
        tempfile.unlink
      end

      it 'reads the file' do
        subject.send(:commit_message).join.should include message
      end
    end
  end
end
