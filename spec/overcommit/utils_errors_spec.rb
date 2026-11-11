# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Utils, 'platform fallbacks and errors' do
  it 'compares version objects as well as strings' do
    expect(described_class::Version.new('2.5')).to be > Gem::Version.new('2.4')
  end

  it 'reports failure to locate the common git directory' do
    allow(described_class).to receive(:execute).and_return(double('result', success?: false))
    expect { described_class.git_dir }.to raise_error(Overcommit::Exceptions::InvalidGitRepo)
  end

  it 'reports failure to resolve a worktree git path' do
    allow(described_class).to receive(:execute).and_return(double('result', success?: false))
    expect { described_class.git_path('config') }.to raise_error(Overcommit::Exceptions::InvalidGitRepo)
  end

  it 'resolves git paths on older Git versions' do
    stub_const('Overcommit::Utils::GIT_VERSION', described_class::Version.new('2.4'))
    expect(described_class).to receive(:execute).with(%w[git rev-parse --git-dir]).
      and_return(double('result', success?: true, stdout: ".git\n"))
    expect(described_class.git_path('config')).to eq(File.expand_path('.git/config'))
  end

  it 'returns false when an executable cannot be found' do
    allow(described_class).to receive(:repo_root).and_return(Dir.pwd)
    allow(File).to receive(:executable?).and_return(false)
    expect(described_class.in_path?('missing')).to eq(false)
  end

  it 'rejects pipes in background commands' do
    expect { described_class.execute_in_background(%w[first | second]) }.
      to raise_error(Overcommit::Exceptions::InvalidCommandArgs, /Cannot pipe/)
  end

  it 'uses procps on Cygwin' do
    allow(Overcommit::OS).to receive_messages(windows?: false, cygwin?: true)
    expect(described_class).to receive(:`).with("procps -ocommand= -p #{Process.ppid}").
      and_return("git commit\n")
    expect(described_class.parent_command).to eq('git commit')
  end

  it 'uses the legacy Git directory command with older Git versions' do
    stub_const('Overcommit::Utils::GIT_VERSION', described_class::Version.new('2.4'))
    expect(described_class).to receive(:execute).with(%w[git rev-parse --git-dir]).
      and_return(double(success?: true, stdout: ".git\n"))
    expect(described_class.git_dir).to eq(File.expand_path('.git'))
  end

  it 'tries Windows executable extensions when PATHEXT is set' do
    allow(described_class).to receive(:repo_root).and_return(Dir.pwd)
    Overcommit::Utils.with_environment('PATHEXT' => '.EXE;.BAT') do
      allow(File).to receive(:executable?).and_return(false)
      expect(File).to receive(:executable?).with(File.join(Dir.pwd, 'tool.EXE')).and_return(true)
      expect(described_class.in_path?('tool')).to eq(true)
    end
  end

  it 'recognizes commands that already have a Windows executable extension' do
    allow(described_class).to receive(:repo_root).and_return(Dir.pwd)
    Overcommit::Utils.with_environment('PATHEXT' => '.EXE') do
      expect(File).to receive(:executable?).with(File.join(Dir.pwd, 'tool.exe')).and_return(true)
      expect(described_class.in_path?('tool.exe')).to eq(true)
    end
  end

  it 'returns no parent command if PowerShell fails' do
    allow(described_class).to receive(:execute).and_return(double(success?: false, stdout: ''))
    expect(described_class.send(:powershell_windows_parent_command)).to be_nil
  end
end
