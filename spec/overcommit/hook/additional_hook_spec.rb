# frozen_string_literal: true

require 'spec_helper'

describe 'Hook configuration edge cases' do
  let(:config) { Overcommit::ConfigurationLoader.default_configuration }

  it 'returns Gerrit script failures to the user' do
    hook = Overcommit::Hook::CommitMsg::GerritChangeId.new(config,
                                                           double('context',
                                                                  commit_message_file: 'msg'))
    allow(hook).to receive(:execute).and_return(double('result', success?: false,
                                                                 stdout: 'script error'))
    expect(hook.run).to eq([:fail, 'script error'])
  end

  it 'passes uncommented commit messages to the spelling checker' do
    hook = Overcommit::Hook::CommitMsg::SpellCheck.new(config,
                                                       double('context', commit_message: 'Subject'))
    message_file = nil
    expect(hook).to receive(:execute) do |command|
      message_file = command.last
      GC.start
      expect(File).to exist(message_file)
      expect(File.read(message_file)).to eq('Subject')
      double('result', success?: true, stdout: '')
    end
    expect(hook.run).to eq(:pass)
    expect(File).not_to exist(message_file)
  end

  it 'removes the spelling checker message file when execution raises' do
    hook = Overcommit::Hook::CommitMsg::SpellCheck.new(config,
                                                       double('context', commit_message: 'Subject'))
    message_file = nil
    expect(hook).to receive(:execute) do |command|
      message_file = command.last
      expect(File).to exist(message_file)
      raise 'spell checker failed'
    end
    expect { hook.run }.to raise_error('spell checker failed')
    expect(File).not_to exist(message_file)
  end

  it 'checks real submodule statuses with the configured recursive option' do
    hook = Overcommit::Hook::PostCommit::SubmoduleStatus.new(config, double('context'))
    expect(Overcommit::GitRepo).to receive(:submodule_statuses).
      with(recursive: hook.config['recursive']).and_return([])
    expect(hook.run).to eq(:pass)
  end

  [true, false].each do |rebase|
    it "updates tags only for rebases (rebase: #{rebase})" do
      hook = Overcommit::Hook::PostRewrite::IndexTags.new(config,
                                                          double('context', rebase?: rebase))
      if rebase
        expect(hook).to receive(:execute_in_background).with([Overcommit::Utils.script_path('index-tags')])
      else
        expect(hook).not_to receive(:execute_in_background)
      end
      expect(hook.run).to eq(:pass)
    end
  end

  it 'describes the configured file size limit' do
    hook = Overcommit::Hook::PreCommit::FileSize.new(config, double('context'))
    expect(hook.description).to match(/Check for files over \d+ bytes/)
  end

  it 'reports executable files from HEAD when the index has no permission changes' do
    hook = Overcommit::Hook::PreCommit::ExecutePermissions.new(config,
                                                               double('context',
                                                                      initial_commit?: false))
    allow(hook).to receive(:applicable_files).and_return(['script'])
    expect(hook).to receive(:execute).with(%w[git ls-tree HEAD --], args: ['script']).
      and_return(double('result', success?: true, stdout: "100755 blob hash\tscript\n"))
    expect(hook).to receive(:execute).with(%w[git diff --raw --cached --no-color --],
                                           args: ['script']).
      and_return(double('result', success?: true, stdout: ''))
    expect(hook.run.map(&:file)).to eq(['script'])
  end

  it 'rejects invalid line ending configuration' do
    allow(config).to receive(:for_hook).and_return({ 'eol' => 'invalid' })
    hook = Overcommit::Hook::PreCommit::LineEndings.new(config, double('context'))
    allow(hook).to receive(:applicable_files).and_return(['file'])
    allow(hook).to receive(:execute).
      and_return(double('result', success?: true, stdout: "i/lf w/lf attr/\tfile\0"))
    expect { hook.run }.to raise_error(/Invalid `eol` option/)
  end
end
