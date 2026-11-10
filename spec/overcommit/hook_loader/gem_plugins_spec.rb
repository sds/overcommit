# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::HookLoader::PluginHookLoader, 'with gem sources' do
  let(:enable_verification) { true }
  let(:hash) do
    {
      'gem_plugins' => { 'PluginFixture' => 'overcommit-unit-fixture' },
      'PreCommit' => {
        'ALL' => { 'enabled' => false },
        'PluginFixture::TestHook' => {
          'enabled' => true, 'requires_files' => false, 'description' => 'Fixture description'
        },
      },
    }
  end
  let(:config) do
    Overcommit::ConfigurationLoader.default_configuration.
      merge(Overcommit::Configuration.new(hash))
  end
  let(:context) { Overcommit::HookContext.create('pre-commit', config, [], StringIO.new) }
  let(:output) { StringIO.new }
  let(:loader) { described_class.new(config, context, Overcommit::Logger.new(output)) }
  let(:gem_root) { File.expand_path('fixture-gem') }
  let(:hook_path) { File.join(gem_root, 'lib/overcommit/hooks/pre_commit/test_hook.rb') }
  let(:specification) do
    spec = Gem::Specification.new do |s|
      s.name = 'overcommit-unit-fixture'
      s.version = '1.0.0'
    end
    allow(spec).to receive(:full_gem_path).and_return(gem_root)
    allow(spec).to receive(:activate)
    spec
  end
  let(:hook_source) do
    <<~RUBY
      require_relative '../../../helper'
      File.write('hook-loaded', 'loaded')
      module Overcommit::Hook::PreCommit::PluginFixture
        class TestHook < Overcommit::Hook::PreCommit::Base
          def run
            File.write('hook-ran', name)
            :pass
          end
        end
      end
    RUBY
  end

  around do |example|
    repo { example.run }
  ensure
    hook_module = Overcommit::Hook::PreCommit
    if hook_module.const_defined?(:PluginFixture, false)
      hook_module.send(:remove_const, :PluginFixture)
    end
    $LOADED_FEATURES.delete_if { |path| path.start_with?(gem_root + File::SEPARATOR) }
  end

  before do
    allow(Gem::Specification).to receive(:find_by_name).and_call_original
    allow(Gem::Specification).to receive(:find_by_name).
      with('overcommit-unit-fixture', anything).and_return(specification)
    FileUtils.mkdir_p(File.dirname(hook_path))
    File.write(hook_path, hook_source)
    File.write(File.join(gem_root, 'lib/helper.rb'), "File.write('helper-loaded', 'loaded')")
  end

  def expect_no_load
    expect(File.exist?('helper-loaded')).to eq(false)
    expect(File.exist?('hook-loaded')).to eq(false)
    expect(File.exist?('hook-ran')).to eq(false)
  end

  it 'rejects unsigned gems before activation, helper loading, or hook loading' do
    expect(specification).not_to receive(:activate)
    expect { loader.load_hooks }.to raise_error(Overcommit::Exceptions::InvalidHookSignature)
    expect(output.string).to include('PluginFixture (gem overcommit-unit-fixture)',
                                     'overcommit --sign pre-commit')
    expect_no_load
  end

  it 'records approval without executing or activating gem code' do
    expect(specification).not_to receive(:activate)
    loader.update_signatures
    expect(output.string).to include('Updated signature of plugin PluginFixture')
    expect_no_load
  end

  it 'instantiates and runs an approved hook with its qualified name and effective settings' do
    loader.update_signatures
    expect(specification).to receive(:activate)
    hook = loader.load_hooks.fetch(0)
    expect(hook.name).to eq('PluginFixture::TestHook')
    expect(hook.description).to eq('Fixture description')
    expect(hook.enabled?).to eq(true)
    expect(hook.run).to eq(:pass)
    expect(File.read('hook-ran')).to eq('PluginFixture::TestHook')
    expect(File.exist?('helper-loaded')).to eq(true)
  end

  it 'accepts repeated signing of approved content without loading code' do
    loader.update_signatures
    loader.update_signatures
    expect(output.string).to include('All plugin signatures have been verified')
    expect_no_load
  end

  it 'rejects changed helpers before loading any code' do
    loader.update_signatures
    File.write(File.join(gem_root, 'lib/helper.rb'), "raise 'untrusted helper'")
    expect(specification).not_to receive(:activate)
    expect { loader.load_hooks }.to raise_error(Overcommit::Exceptions::InvalidHookSignature)
    expect_no_load
  end

  it 'does not reuse approval for different effective hook configuration' do
    loader.update_signatures
    updated = config.merge(Overcommit::Configuration.new(
                             'PreCommit' => { 'PluginFixture::TestHook' => { 'description' => 'Changed' } }
    ))
    other = described_class.new(updated, context, Overcommit::Logger.silent)
    expect { other.load_hooks }.to raise_error(Overcommit::Exceptions::InvalidHookSignature)
    expect_no_load
  end

  it 'checks repository hook approvals before requiring approved gem code' do
    loader.update_signatures
    FileUtils.mkdir_p('.git-hooks/pre_commit')
    File.write('.git-hooks/pre_commit/untrusted.rb', "raise 'untrusted repository hook'")
    expect { loader.load_hooks }.to raise_error(Overcommit::Exceptions::InvalidHookSignature)
    expect_no_load
  end

  it 'reuses a module namespace without confusing it with a built-in hook' do
    Overcommit::Hook::PreCommit.const_set(:PluginFixture, Module.new)
    loader.update_signatures
    expect(loader.load_hooks.map(&:name)).to eq(['PluginFixture::TestHook'])
  end

  it 'rejects a namespace that would overwrite a built-in class' do
    hash['gem_plugins'] = { 'Base' => 'overcommit-unit-fixture' }
    hash['PreCommit']['Base::TestHook'] = hash['PreCommit'].delete('PluginFixture::TestHook')
    loader.update_signatures
    expect { loader.load_hooks }.to raise_error(Overcommit::Exceptions::HookLoadError,
                                                /conflicts with an existing hook/)
    expect_no_load
  end

  it 'does not resolve or load sources whose hooks are disabled' do
    hash['PreCommit']['PluginFixture::TestHook']['enabled'] = false
    expect(Gem::Specification).not_to receive(:find_by_name)
    expect(loader.load_hooks).to eq([])
    expect_no_load
  end

  context 'when the gem defines an invalid hook class' do
    let(:hook_source) { 'Overcommit::Hook::PreCommit::PluginFixture::TestHook = 123' }

    it 'reports an invalid subclass instead of an internal error' do
      loader.update_signatures
      expect { loader.load_hooks }.to raise_error(Overcommit::Exceptions::HookLoadError,
                                                  /not a subclass/)
    end
  end

  context 'when the gem does not define the requested hook constant' do
    let(:hook_source) { '# No hook constant' }

    it 'reports the qualified name in a loading error' do
      loader.update_signatures
      expect { loader.load_hooks }.to raise_error(Overcommit::Exceptions::HookLoadError,
                                                  /Unable to load hook 'PluginFixture::TestHook'/)
    end
  end
end
