# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Subprocess do
  # Absolute path to the Ruby currently running the specs. Using this instead of
  # a bare `ruby` keeps these specs working regardless of what is on the PATH.
  let(:ruby) { Gem.ruby }

  # Script which writes its own ARGV to standard output, using NUL as the
  # separator so that arguments containing whitespace remain distinguishable.
  let(:argv_dump) { 'STDOUT.print ARGV.join("\0")' }

  # Splits the output of `argv_dump` back into the array the child received.
  def received_argv(result)
    result.stdout.split("\0", -1)
  end

  describe '.spawn' do
    context 'when the command succeeds' do
      subject do
        described_class.spawn([ruby, '-e', 'STDOUT.print "hello"; STDERR.print "world"'])
      end

      it 'returns a successful result containing the captured output' do
        subject.should be_a described_class::Result
        subject.should be_success
        subject.status.should == 0
        subject.stdout.should == 'hello'
        subject.stderr.should == 'world'
      end
    end

    context 'when the command fails' do
      subject do
        described_class.spawn([ruby, '-e', 'STDERR.print "boom"; exit 42'])
      end

      it 'returns an unsuccessful result containing the exit status' do
        subject.should_not be_success
        subject.status.should == 42
        subject.stdout.should == ''
        subject.stderr.should == 'boom'
      end
    end

    context 'when given input' do
      subject do
        described_class.spawn([ruby, '-e', 'STDOUT.print STDIN.read'], input: 'from-stdin')
      end

      it 'passes the input to the standard input stream of the process' do
        subject.should be_success
        subject.stdout.chomp.should == 'from-stdin'
      end
    end

    context 'when an argument contains whitespace and a dash-prefixed token' do
      # Regression test for https://github.com/sds/overcommit/issues/847, where
      # arguments were joined into a single string before being handed to the
      # shell, causing the child to re-split them on whitespace. This made
      # `git stash save` interpret the tail of the stash message (the UTC offset)
      # as a switch of its own, failing with `unknown switch '0'`.
      let(:stash_message) do
        'Overcommit: Stash of repo state before hook run at 2024-04-10 12:34:56 -0700'
      end

      subject do
        described_class.spawn([ruby, '-e', argv_dump, 'save', stash_message])
      end

      it 'delivers the argument to the child as a single atomic argument' do
        subject.should be_success
        received_argv(subject).should == ['save', stash_message]
      end
    end

    context 'when arguments contain shell metacharacters' do
      let(:tricky_args) do
        [
          'a&b',
          'a|b',
          'a>b',
          'a<b',
          '(parens)',
          'caret^escape',
          'say "hi" now',
          "it's quoted",
          'literal%PATH%'
        ]
      end

      subject { described_class.spawn([ruby, '-e', argv_dump, *tricky_args]) }

      it 'delivers the arguments to the child untouched' do
        subject.should be_success
        received_argv(subject).should == tricky_args
      end
    end

    context 'when an argument is empty' do
      subject { described_class.spawn([ruby, '-e', argv_dump, '', 'after']) }

      it 'preserves the empty argument' do
        subject.should be_success
        received_argv(subject).should == ['', 'after']
      end
    end
  end

  # Subprocess no longer branches on platform, but this guards against
  # reintroducing a shell wrapper -- if one came back, this would catch it
  # from CI (which only runs Linux -- see
  # https://github.com/sds/overcommit/issues/836).
  describe 'the argument vector handed to ChildProcess' do
    let(:args) do
      ['git', 'stash', 'save', '--quiet', 'Overcommit: Stash at 2024-04-10 12:34:56 -0700']
    end

    let(:io) { double('io', :stdout= => nil, :stderr= => nil) }

    let(:process) do
      double(
        'process',
        io: io,
        :duplex= => nil,
        :detach= => nil,
        start: nil,
        wait: nil,
        exit_code: 0
      )
    end

    it 'passes the arguments through verbatim from .spawn' do
      ChildProcess.should_receive(:build).with(*args).and_return(process)
      described_class.spawn(args)
    end

    it 'passes the arguments through verbatim from .spawn_detached' do
      ChildProcess.should_receive(:build).with(*args).and_return(process)
      described_class.spawn_detached(args)
    end
  end
end
