# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::GemPlugin do
  let(:config_hash) do
    {
      'gem_plugins' => { 'Company' => 'company-hooks' },
      'PreCommit' => {
        'Company::Check' => { 'enabled' => true, 'requires_files' => false },
        'Company::Disabled' => { 'enabled' => false },
      },
    }
  end
  let(:config) { Overcommit::Configuration.new(config_hash) }
  let(:context) { double(hook_class_name: 'PreCommit', hook_type_name: 'pre_commit') }
  let(:plugin) { described_class.new('Company', config, context) }
  let(:gem_root) { File.expand_path('fixture-gem') }
  let(:specification) { make_specification('company-hooks', gem_root) }

  def make_specification(name, root)
    spec = Gem::Specification.new do |s|
      s.name = name
      s.version = '1.0.0'
      s.summary = 'Fixture'
      s.author = 'Overcommit'
    end
    allow(spec).to receive(:full_gem_path).and_return(root)
    allow(Gem::Specification).to receive(:find_by_name).with(name, anything).and_return(spec)
    spec
  end

  def write_gem_file(path, contents = '# fixture')
    target = File.join(gem_root, path)
    FileUtils.mkdir_p(File.dirname(target))
    File.write(target, contents)
  end

  def changed_config(hash)
    described_class.new('Company', Overcommit::Configuration.new(hash), context)
  end

  around do |example|
    repo { example.run }
  end

  before do
    allow(Gem::Specification).to receive(:find_by_name).and_call_original
    specification
    write_gem_file('lib/overcommit/hooks/pre_commit/check.rb')
    write_gem_file('lib/company_hooks.rb')
    write_gem_file('lib/helper.rb')
    write_gem_file('.hidden-data')
  end

  it 'finds only enabled hooks within the declared gem without requiring its entrypoint' do
    expect(plugin.hook_names).to eq(['Company::Check'])
    expect(plugin).not_to receive(:require)
    expect(plugin.hook_paths).to eq([File.join(gem_root,
                                               'lib/overcommit/hooks/pre_commit/check.rb')])
  end

  it 'does not activate the gem while approving it' do
    expect(specification).not_to receive(:activate)
    plugin.update_signature!
    expect(plugin.signature_verified?).to eq(true)
  end

  it 'does not trust a gem that has not been approved' do
    expect(plugin.signature_verified?).to eq(false)
  end

  %w[lib/company_hooks.rb lib/helper.rb .hidden-data README.md].each do |path|
    it "requires approval when #{path} changes, even if absent from gemspec files" do
      plugin.update_signature!
      write_gem_file(path, 'changed')
      expect(plugin.signature_verified?).to eq(false)
    end
  end

  it 'requires approval when files are removed' do
    plugin.update_signature!
    File.unlink(File.join(gem_root, 'lib/helper.rb'))
    expect(plugin.signature_verified?).to eq(false)
  end

  it 'requires approval when a file is renamed without changing contents' do
    plugin.update_signature!
    File.rename(File.join(gem_root, 'lib/helper.rb'), File.join(gem_root, 'lib/renamed.rb'))
    expect(plugin.signature_verified?).to eq(false)
  end

  it 'covers the gem version' do
    plugin.update_signature!
    specification.version = '1.1.0'
    expect(plugin.signature_verified?).to eq(false)
  end

  it 'covers the gem require paths' do
    plugin.update_signature!
    specification.require_paths = %w[lib other]
    expect(plugin.signature_verified?).to eq(false)
  end

  it 'covers compiled extensions outside the gem directory' do
    extension_root = File.expand_path('extensions/company-hooks')
    FileUtils.mkdir_p(extension_root)
    extension = File.join(extension_root, 'native.so')
    File.binwrite(extension, "\x00\x01\xff")
    allow(specification).to receive(:full_require_paths).
      and_return([File.join(gem_root, 'lib'), extension_root])
    plugin.update_signature!
    File.binwrite(extension, "\x00\x02\xff")
    expect(plugin.signature_verified?).to eq(false)
  end

  it 'covers effective hook settings including inherited ALL settings' do
    plugin.update_signature!
    config_hash['PreCommit']['ALL'] = { 'description' => 'Changed setting' }
    expect(changed_config(config_hash).signature_verified?).to eq(false)
  end

  it 'does not treat SKIP or ONLY as a change in trusted configuration' do
    plugin.update_signature!
    config.apply_environment!(context, 'ONLY' => 'Company::Check')
    expect(plugin.signature_verified?).to eq(true)
  end

  it 'does not allow an approval for one hook type to approve another' do
    plugin.update_signature!
    other_context = double(hook_class_name: 'PrePush', hook_type_name: 'pre_push')
    other = described_class.new('Company', config, other_context)
    expect(other.signature_verified?).to eq(false)
  end

  it 'remembers approvals after trusted content is restored' do
    original = File.read(File.join(gem_root, 'lib/helper.rb'))
    plugin.update_signature!
    write_gem_file('lib/helper.rb', 'changed')
    plugin.update_signature!
    write_gem_file('lib/helper.rb', original)
    expect(plugin.signature_verified?).to eq(true)
  end

  it 'ignores Git metadata when signing path gems' do
    plugin.update_signature!
    write_gem_file('.git/config', 'metadata')
    expect(plugin.signature_verified?).to eq(true)
  end

  it 'reports missing enabled hooks before requiring any code' do
    File.unlink(plugin.hook_paths.first)
    expect { plugin.hook_paths }.to raise_error(Overcommit::Exceptions::HookLoadError,
                                                /does not provide Company::Check/)
  end

  it 'rejects undeclared namespaces' do
    expect { described_class.new('Unknown', config, context) }.
      to raise_error(Overcommit::Exceptions::HookLoadError, /Declare the gem/)
  end

  it 'reports unavailable gems with installation guidance' do
    allow(Gem::Specification).to receive(:find_by_name).
      with('company-hooks', anything).and_raise(Gem::LoadError, 'missing')
    expect { plugin.hook_paths }.to raise_error(Overcommit::Exceptions::HookLoadError,
                                                /Install the gem.*Gemfile/)
  end

  it 'uses an already activated gem rather than finding a different installed version' do
    allow(Gem).to receive(:loaded_specs).and_return('company-hooks' => specification)
    expect(Gem::Specification).not_to receive(:find_by_name)
    expect(plugin.hook_path).to eq(gem_root)
  end

  it 'rejects symbolic links instead of trusting code outside the signed tree' do
    skip 'Symlink creation requires privileges on Windows' if Overcommit::OS.windows?
    FileUtils.mkdir_p('outside')
    File.write('outside/helper.rb', '# external')
    File.symlink(File.expand_path('outside'), File.join(gem_root, 'lib/outside'))
    expect { plugin.update_signature! }.to raise_error(Overcommit::Exceptions::HookLoadError,
                                                       /symbolic links/)
  end

  it 'reports unreadable contents rather than trusting an incomplete digest' do
    allow(Digest::SHA256).to receive(:file).and_raise(Errno::EACCES)
    expect { plugin.signature_verified? }.to raise_error(Overcommit::Exceptions::HookLoadError,
                                                         /Unable to read gem plugin/)
  end

  context 'with runtime dependencies' do
    let(:dependency_root) { File.expand_path('dependency-gem') }
    let(:dependency) { make_specification('company-helper', dependency_root) }

    before do
      specification.add_runtime_dependency('company-helper', '~> 1.0')
      dependency
      FileUtils.mkdir_p(File.join(dependency_root, 'lib'))
      File.write(File.join(dependency_root, 'lib/helper.rb'), '# helper')
    end

    it 'covers dependency contents, even when the plugin itself has not changed' do
      plugin.update_signature!
      File.write(File.join(dependency_root, 'lib/helper.rb'), '# changed helper')
      expect(plugin.signature_verified?).to eq(false)
    end

    it 'fails closed if no dependency contents can be found for approval' do
      FileUtils.rm_rf(dependency_root)
      expect { plugin.update_signature! }.to raise_error(Overcommit::Exceptions::HookLoadError,
                                                         /Unable to find contents/)
    end

    it 'covers transitive dependencies and terminates on dependency cycles' do
      dependency.add_runtime_dependency('company-hooks', '~> 1.0')
      dependency.add_runtime_dependency('company-transitive', '~> 1.0')
      transitive_root = File.expand_path('transitive-gem')
      make_specification('company-transitive', transitive_root)
      FileUtils.mkdir_p(transitive_root)
      File.write(File.join(transitive_root, 'data'), 'original')
      plugin.update_signature!
      File.write(File.join(transitive_root, 'data'), 'changed')
      expect(plugin.signature_verified?).to eq(false)
    end

    it 'rejects incompatible already activated dependencies' do
      dependency.version = '2.0.0'
      allow(Gem).to receive(:loaded_specs).and_return('company-helper' => dependency)
      expect { plugin.signature_verified? }.to raise_error(Overcommit::Exceptions::HookLoadError,
                                                           /does not satisfy/)
    end

    it 'activates the resolved gems only when explicitly requested to load them' do
      expect(specification).to receive(:activate)
      expect(dependency).to receive(:activate)
      plugin.activate
    end

    it 'reports activation conflicts clearly' do
      allow(specification).to receive(:activate).and_raise(Gem::LoadError, 'conflict')
      allow(dependency).to receive(:activate)
      expect { plugin.activate }.to raise_error(Overcommit::Exceptions::HookLoadError,
                                                /Unable to activate company-hooks/)
    end
  end
end
