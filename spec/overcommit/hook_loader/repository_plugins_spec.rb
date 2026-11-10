# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::HookLoader::PluginHookLoader, 'with repository plugins' do
  let(:enable_verification) { true }
  let(:config) { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { Overcommit::HookContext.create('pre-commit', config, [], StringIO.new) }
  let(:loader) { described_class.new(config, context, Overcommit::Logger.silent) }
  let(:plugin_path) { File.join(config.plugin_directory, 'pre_commit/coverage_fixture.rb') }

  around do |example|
    repo do
      example.run
    ensure
      $LOADED_FEATURES.delete(plugin_path)
      hook_module = Overcommit::Hook::PreCommit
      if hook_module.const_defined?(:CoverageFixture, false)
        hook_module.send(:remove_const, :CoverageFixture)
      end
    end
  end

  before do
    FileUtils.mkdir_p(File.dirname(plugin_path))
    File.write(plugin_path, <<~RUBY)
      module Overcommit::Hook::PreCommit
        class CoverageFixture < Base
          def run
            :pass
          end
        end
      end
    RUBY
    Overcommit::Utils.execute(['git', 'add', plugin_path])
  end

  it 'loads and instantiates a signed repository hook' do
    loader.update_signatures
    hook = loader.load_hooks.fetch(0)
    expect(hook.name).to eq('CoverageFixture')
    expect(hook.run).to eq(:pass)
  end

  it 'rejects changed plugin contents before requiring them' do
    loader.update_signatures
    File.write(plugin_path, "raise 'unapproved code ran'")
    expect { loader.load_hooks }.to raise_error(Overcommit::Exceptions::InvalidHookSignature)
    expect(Overcommit::Hook::PreCommit.const_defined?(:CoverageFixture, false)).to eq(false)
  end
end
