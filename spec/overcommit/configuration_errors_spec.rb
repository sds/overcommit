# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::ConfigurationLoader, 'loading failures and verification' do
  let(:logger) { Overcommit::Logger.silent }
  let(:loader) { described_class.new(logger, verify: true) }
  let(:config) { double('config', previous_signature?: true, signature_verified?: true) }

  before do
    allow(described_class).to receive(:load_from_file).and_call_original
    allow(described_class).to receive(:load_from_file).with('config.yml', default: false,
                                                                          logger: logger).
      and_return(config)
    allow(described_class.default_configuration).to receive(:merge).with(config).and_return(config)
  end

  it 'returns a configuration with a trusted signature' do
    expect(loader.load_file('config.yml')).to eq(config)
  end

  it 'requires approval for an unsigned configuration' do
    allow(config).to receive(:previous_signature?).and_return(false)
    expect { loader.load_file('config.yml') }.
      to raise_error(Overcommit::Exceptions::ConfigurationSignatureChanged,
                     /No previously recorded signature/)
  end

  it 'requires approval when the signature has changed' do
    allow(config).to receive(:signature_verified?).and_return(false)
    expect { loader.load_file('config.yml') }.
      to raise_error(Overcommit::Exceptions::ConfigurationSignatureChanged, /has changed/)
  end

  it 'includes the filename and original error for malformed YAML' do
    allow(described_class).to receive(:load_from_file).and_raise('invalid YAML')
    expect { loader.load_file('config.yml') }.
      to raise_error(Overcommit::Exceptions::ConfigurationError, /config.yml.*invalid YAML/)
  end

  it 'falls back to YAML loaders that do not support keyword options' do
    expect(YAML).to receive(:load_file).
      with('legacy.yml', permitted_classes: [Regexp,
                                             Symbol], aliases: true).and_raise(ArgumentError)
    expect(YAML).to receive(:load_file).with('legacy.yml').and_return({})
    expect(described_class.load_from_file('legacy.yml', verify: false)).to be_a(Overcommit::Configuration)
  end
end

describe Overcommit::Configuration, 'signature settings' do
  let(:config) { described_class.new({ 'verify_signatures' => false }, validate: false) }
  let(:enable_verification) { true }

  before { allow(Overcommit::GitConfig).to receive(:signature_scope).and_return('--local') }

  { 1 => ['', true], 0 => ['0', false], 2 => ['error', nil] }.each do |status, (stdout, expected)|
    it "handles git config exit status #{status}" do
      allow(Overcommit::Utils).to receive(:execute).
        and_return(double('result', status: status, stdout: stdout, stderr: 'broken config'))
      if expected.nil?
        expect { config.verify_signatures? }.
          to raise_error(Overcommit::Exceptions::GitConfigError, /broken config/)
      else
        expect(config.verify_signatures?).to eq(expected)
      end
    end
  end

  it 'checks whether a signature has been recorded and approved' do
    store = double('signature store', recorded?: true, include?: true)
    allow(Overcommit::Signature).to receive(:new).and_return(store)
    expect(config.previous_signature?).to eq(true)
    expect(config.signature_verified?).to eq(true)
  end

  it 'reports a failure to write signature verification settings' do
    store = double('signature store', add: nil)
    allow(Overcommit::Signature).to receive(:new).and_return(store)
    allow(Overcommit::Utils).to receive(:execute).
      and_return(double('result', success?: false, stderr: 'read-only config'))
    expect { config.update_signature! }.
      to raise_error(Overcommit::Exceptions::GitConfigError, /read-only config/)
  end

  it 'evaluates processor arithmetic in concurrency settings' do
    allow(Overcommit::Utils).to receive(:processor_count).and_return(4)
    config = described_class.new({ 'concurrency' => '%<processors>d * 2' }, validate: false)
    expect(config.concurrency).to eq(8)
  end

  it 'discovers and configures filesystem plugins' do
    repo do
      FileUtils.mkdir_p('.git-hooks/pre_commit')
      File.write('.git-hooks/pre_commit/example_hook.rb', '# plugin')
      config = Overcommit::ConfigurationLoader.default_configuration
      expect(config.all_plugin_hook_configs['PreCommit']['ExampleHook']).
        to eq(config.for_hook('ExampleHook', 'PreCommit'))
    end
  end
end

describe Overcommit::OS do
  { 'darwin' => [true, true, false, false], 'linux' => [false, true, true, false],
    'mingw' => [false, false, false, false], 'cygwin' => [false, true, false, true] }.
    each do |os, expected|
    it "identifies #{os}" do
      allow(described_class).to receive(:host_os).and_return(os)
      expect([described_class.mac?, described_class.unix?, described_class.linux?,
              described_class.cygwin?]).to eq(expected)
    end
  end
end

describe Overcommit::ConfigurationValidator, 'legacy and invalid settings' do
  it 'rejects a hook environment that is not a hash' do
    expect do
      Overcommit::Configuration.new('PreCommit' => { 'Example' => { 'env' => ['invalid'] } })
    end.to raise_error(Overcommit::Exceptions::ConfigurationError, /invalid `env`/)
  end

  it 'warns about the renamed plugin signature option' do
    logger = Overcommit::Logger.new(StringIO.new)
    expect(logger).to receive(:warning).with(/has been renamed/)
    expect(logger).to receive(:warning).with(/change log/)
    Overcommit::Configuration.new({ 'verify_plugin_signatures' => false }, logger: logger)
  end
end
