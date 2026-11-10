# frozen_string_literal: true

require 'spec_helper'
require 'overcommit/cli'

describe Overcommit::CLI, 'command results and errors' do
  let(:output) { StringIO.new }
  let(:logger) { Overcommit::Logger.new(output) }
  let(:arguments) { [] }
  let(:cli) { described_class.new(arguments, StringIO.new, logger) }

  it 'prints help and exits successfully' do
    arguments << '--help'
    expect { cli.run }.to raise_error(SystemExit) { |error| expect(error.status).to eq(0) }
    expect(output.string).to include('Usage:')
  end

  it 'prints the version and exits successfully' do
    arguments << '--version'
    expect { cli.run }.to raise_error(SystemExit) { |error| expect(error.status).to eq(0) }
    expect(output.string).to include(Overcommit::VERSION)
  end

  it 'prints help for an invalid option and exits with usage status' do
    arguments << '--invalid-option'
    expect { cli.run }.to raise_error(SystemExit) { |error| expect(error.status).to eq(64) }
    expect(output.string).to include('invalid option', 'Usage:')
  end

  it 'explains how to install outside a repository' do
    allow(Overcommit::Utils).to receive(:repo_root).and_return(nil)
    expect { cli.run }.to raise_error(SystemExit) { |error| expect(error.status).to eq(64) }
    expect(output.string).to include('not in a git repository', 'specify the path')
  end

  { InvalidGitRepo: 69, PreExistingHooks: 73 }.each do |exception, status|
    it "reports installation error #{exception}" do
      arguments.concat(['--install', '--force', 'target'])
      installer = double('installer')
      allow(Overcommit::Installer).to receive(:new).and_return(installer)
      expect(installer).to receive(:run).with('target', hash_including(force: true)).
        and_raise(Overcommit::Exceptions.const_get(exception), 'explanation')
      expect { cli.run }.to raise_error(SystemExit) { |error| expect(error.status).to eq(status) }
      expect(output.string).to include('explanation')
    end
  end

  { ConfigurationSignatureChanged: 78, InvalidHookSignature: 78, ConfigurationError: 78,
    HookLoadError: 78, HookContextLoadError: 64 }.each do |exception, status|
    it "uses the expected exit status for #{exception}" do
      allow(cli).to receive(:install_or_uninstall).
        and_raise(Overcommit::Exceptions.const_get(exception), 'explanation')
      capture_stdout do
        expect { cli.run }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(status)
        end
      end
    end
  end

  it 'signs the configuration without verifying its old signature' do
    arguments << '--sign'
    config = double('config')
    expect(cli).to receive(:config).with(verify: false).and_return(config)
    expect(config).to receive(:update_signature!)
    expect { cli.run }.to raise_error(SystemExit) { |error| expect(error.status).to eq(0) }
  end

  it 'updates signatures for an explicitly selected hook type' do
    arguments.concat(['--sign', 'pre-commit'])
    config = double('config')
    context = double('context')
    loader = double('loader')
    allow(cli).to receive(:config).and_return(config)
    expect(Overcommit::HookContext).to receive(:create).
      with('pre-commit', config, [], instance_of(StringIO)).and_return(context)
    expect(Overcommit::HookLoader::PluginHookLoader).to receive(:new).
      with(config, context, logger).and_return(loader)
    expect(loader).to receive(:update_signatures)
    expect { cli.run }.to raise_error(SystemExit)
  end

  it 'labels enabled, disabled, and plugin hooks in the list' do
    arguments << '--list-hooks'
    config = double('config', all_hook_configs: {
                      'PreCommit' => { 'Example' => { 'enabled' => true }, 'Other' => {} }
                    })
    allow(cli).to receive(:config).and_return(config)
    allow(config).to receive(:plugin_hook?).with('PreCommit', 'Example').and_return(true)
    allow(config).to receive(:plugin_hook?).with('PreCommit', 'Other').and_return(false)
    expect { cli.run }.to raise_error(SystemExit)
    expect(output.string).to include('Example: enabled (plugin)', 'Other: disabled')
  end
end
