require 'spec_helper'

describe Overcommit::CommandSplitter do
  describe '.execute' do
    let(:args_prefix) { %w[cmd] }
    let(:max_command_length) { 10 }
    let(:options) { { args: splittable_args } }

    subject { described_class.execute(args_prefix, options) }

    before do
      described_class.stub(:max_command_length).and_return(max_command_length)

      Overcommit::Subprocess.stub(:spawn).
        and_return(Overcommit::Subprocess::Result.new(0, 'output', 'error'))
    end

    context 'with no splittable arguments' do
      let(:splittable_args) { [] }

      it 'raises an error' do
        expect { subject }.to raise_error Overcommit::Exceptions::InvalidCommandArgs
      end
    end

    context 'with splittable arguments under the limit' do
      let(:splittable_args) { %w[1 2 3 4 5 6 7] }

      it 'executes one command' do
        Overcommit::Subprocess.should_receive(:spawn).once
        subject
      end
    end

    context 'with splittable arguments just over the limit' do
      let(:splittable_args) { %w[1 2 3 4 5 6 7 8] }

      it 'executes two commands with the appropriately split arguments' do
        Overcommit::Subprocess.should_receive(:spawn).with(%w[cmd 1 2 3 4 5 6 7],
                                                           hash_excluding(:args))
        Overcommit::Subprocess.should_receive(:spawn).with(%w[cmd 8],
                                                           hash_excluding(:args))
        subject
      end

      context 'when both commands return successfully' do
        it 'returns a successful result' do
          subject.should be_success
          subject.status.should == 0
        end

        it 'returns concatenated output' do
          subject.stdout.should == 'output' * 2
          subject.stderr.should == 'error' * 2
        end
      end

      context 'when one command fails' do
        before do
          Overcommit::Subprocess.stub(:spawn).
            with(%w[cmd 8], anything).
            and_return(Overcommit::Subprocess::Result.new(2, 'whoa', 'bad error'))
        end

        it 'returns an unsuccessful result' do
          subject.should_not be_success
          subject.status.should == 1
        end

        it 'returns concatenated output' do
          subject.stdout.should == 'outputwhoa'
          subject.stderr.should == 'errorbad error'
        end
      end
    end

    context 'with splittable arguments well over the limit' do
      let(:splittable_args) { Array.new(15) { |i| (i + 1).to_s } }

      it 'executes multiple commands with the appropriately split arguments' do
        Overcommit::Subprocess.should_receive(:spawn).with(%w[cmd 1 2 3 4 5 6 7],
                                                           hash_excluding(:args))
        Overcommit::Subprocess.should_receive(:spawn).with(%w[cmd 8 9 10 11],
                                                           hash_excluding(:args))
        Overcommit::Subprocess.should_receive(:spawn).with(%w[cmd 12 13 14],
                                                           hash_excluding(:args))
        Overcommit::Subprocess.should_receive(:spawn).with(%w[cmd 15],
                                                           hash_excluding(:args))
        subject
      end
    end

    context 'with a splittable argument that on its own exceeds the limit' do
      let(:splittable_args) { %w[1 2 ohmylookareallylongargument] }

      it 'executes no commands and raises an exception' do
        Overcommit::Subprocess.should_not_receive(:spawn)
        expect { subject }.to raise_error Overcommit::Exceptions::InvalidCommandArgs
      end
    end

    context 'with a command prefix that exceeds the limit' do
      let(:args_prefix) { %w[reallylong] }
      let(:splittable_args) { %w[1 2 3] }

      it 'executes no commands and raises an exception' do
        Overcommit::Subprocess.should_not_receive(:spawn)
        expect { subject }.to raise_error Overcommit::Exceptions::InvalidCommandArgs
      end
    end

    context 'with a standard input stream specified' do
      let(:max_command_length) { 5 }
      let(:args_prefix) { %w[cat] }
      let(:options) { { args: %w[- - -], input: 'Hello' } }

      it 'passes the same standard input to each command' do
        Overcommit::Subprocess.should_receive(:spawn).with(%w[cat - -],
                                                           hash_including(input: 'Hello'))
        Overcommit::Subprocess.should_receive(:spawn).with(%w[cat -],
                                                           hash_including(input: 'Hello'))
        subject
      end
    end
  end
end
