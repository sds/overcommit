# frozen_string_literal: true

require 'spec_helper'
require 'overcommit/hook_context/run_all'
require 'overcommit/hook_context/pre_push'
require 'overcommit/hook_context/commit_msg'
require 'overcommit/hook_context/prepare_commit_msg'

describe Overcommit::HookContext::Base do
  it 'forwards hook arguments and stdin to commands' do
    context = described_class.new(nil, ['argument'], StringIO.new("input\n"))
    expect(Overcommit::Utils).to receive(:execute).
      with(['command'], args: ['argument'], input: "input\n").and_return(:result)
    expect(context.execute_hook(['command'])).to eq(:result)
    expect(context.modified_files).to eq([])
  end
end

describe Overcommit::HookContext do
  it 'reports unsupported hook types' do
    expect { described_class.create('nonexistent', nil, [], nil) }.
      to raise_error(Overcommit::Exceptions::HookContextLoadError)
  end
end

describe Overcommit::HookContext::RunAll do
  it 'caches whether this is an initial commit, including false results' do
    context = described_class.new(nil, [], nil)
    expect(Overcommit::GitRepo).to receive(:initial_commit?).once.and_return(false)
    2.times { expect(context.initial_commit?).to eq(false) }
  end
end

describe Overcommit::HookContext::CommitMsg do
  it 'writes a replacement commit message' do
    Tempfile.create('message') do |file|
      context = described_class.new(nil, [file.path], nil)
      context.update_commit_message("Replacement\n")
      expect(File.read(file.path)).to eq("Replacement\n")
    end
  end
end

describe Overcommit::HookContext::PrepareCommitMsg do
  it 'uses an explicitly supplied source reference' do
    context = described_class.new(nil, %w[message commit reference], nil)
    expect(context.commit_message_source_ref).to eq('reference')
  end

  it 'looks up HEAD when no source reference is supplied' do
    context = described_class.new(nil, ['message'], nil)
    expect(context).to receive(:`).with('git rev-parse HEAD').and_return("reference\n")
    expect(context.commit_message_source_ref).to eq("reference\n")
  end
end

describe Overcommit::HookContext::PrePush::PushedRef do
  it 'renders the original input line' do
    expect(described_class.new('local', 'abc', 'remote', 'def').to_s).to eq('local abc remote def')
  end

  it 'detects a forced update when remote commits would be overwritten' do
    ref = described_class.new('local', 'abc', 'remote', 'def')
    expect(Overcommit::Subprocess).to receive(:spawn).with(%w[git rev-list def ^abc]).
      and_return(double('result', success?: true, stdout: "overwritten\n"))
    expect(ref.forced?).to eq(true)
  end
end
