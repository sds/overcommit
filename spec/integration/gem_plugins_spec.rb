# frozen_string_literal: true

require 'spec_helper'
require 'rubygems/package'
require 'rubygems/installer'
require 'yaml'

describe 'gem-provided hooks and approvals' do
  let(:enable_verification) { true }
  let(:namespace) { 'Company' }
  let(:gem_name) { 'overcommit-fixture-hooks' }
  let(:bundled) { false }
  let(:config) do
    {
      'gem_plugins' => { namespace => gem_name },
      'CommitMsg' => { 'ALL' => { 'enabled' => false } },
      'PreCommit' => {
        'ALL' => { 'enabled' => false },
        "#{namespace}::Check" => { 'enabled' => true, 'requires_files' => false },
      },
    }
  end
  let(:hook_source) do
    <<~RUBY
      require 'fixture_helper'
      require 'overcommit_fixture_hooks'
      File.write('hook-loaded', 'loaded')
      module Overcommit::Hook::PreCommit::#{namespace}
        class Check < Overcommit::Hook::PreCommit::Base
          def run
            File.write('hook-ran', name)
            :pass
          end
        end
      end
    RUBY
  end

  def command(*arguments)
    result = shell(arguments)
    expect(result.status).to eq(0), "#{arguments.inspect}: #{result.stdout}\n#{result.stderr}"
    result
  end

  def cli(*arguments)
    shell([RbConfig.ruby, '-I', File.join(Overcommit::HOME, 'lib'),
           File.join(Overcommit::HOME, 'bin/overcommit')] + arguments)
  end

  def successful_cli(*arguments)
    result = cli(*arguments)
    expect(result.status).to eq(0), "#{arguments.inspect}: #{result.stdout}\n#{result.stderr}"
    result
  end

  def write_config
    File.write('.overcommit.yml', config.to_yaml)
  end

  def approve
    successful_cli('--sign')
    successful_cli('--sign', 'pre-commit')
    expect_no_load
  end

  def expect_no_load
    %w[dependency-loaded entrypoint-loaded hook-loaded hook-ran].each do |marker|
      expect(File.exist?(marker)).to eq(false), "Untrusted code created #{marker}"
    end
  end

  def commit
    shell(%w[git commit --allow-empty -m Test])
  end

  def install_fixture(name, files, dependencies = {}) # rubocop:disable Metrics/MethodLength
    source = File.join(@fixture_root, 'source', name)
    FileUtils.mkdir_p(source)
    files.each do |path, contents|
      FileUtils.mkdir_p(File.dirname(File.join(source, path)))
      File.write(File.join(source, path), contents)
    end
    spec = Gem::Specification.new do |s|
      s.name = name
      s.version = '1.0.0'
      s.author = 'Overcommit'
      s.summary = 'Local fixture for gem plugin integration tests'
      s.license = 'MIT'
      s.homepage = 'https://example.com'
      s.files = files.keys
      dependencies.each do |dependency, requirement|
        s.add_runtime_dependency(dependency, requirement)
      end
    end
    Gem::DefaultUserInteraction.use_ui(Gem::SilentUI.new) do
      Dir.chdir(source) do
        package = Gem::Package.build(spec)
        Gem::Installer.at(package, install_dir: @gem_home, ignore_dependencies: true,
                                   wrappers: false).install
      end
    end
    File.join(@gem_home, 'gems', "#{name}-1.0.0")
  end

  around do |example|
    installed_paths = ([Bundler.bundle_path.to_s] + Gem.path).uniq
    Dir.mktmpdir('overcommit-plugin-gems') do |fixtures|
      @fixture_root = fixtures
      @gem_home = File.join(fixtures, 'installed')
      helper_files = { 'lib/fixture_helper.rb' => "File.write('dependency-loaded', 'loaded')" }
      @dependency_root = install_fixture('fixture-helper', helper_files)
      files = {
        'lib/overcommit_fixture_hooks.rb' => "File.write('entrypoint-loaded', 'loaded')",
        'lib/overcommit/hooks/pre_commit/check.rb' => hook_source,
        'lib/helper.rb' => '# helper',
      }
      @plugin_root = install_fixture(gem_name, files, 'fixture-helper' => '~> 1.0')
      repo do
        Bundler.with_unbundled_env do
          env = {
            'GEM_HOME' => @gem_home,
            'GEM_PATH' => ([@gem_home] + installed_paths).join(File::PATH_SEPARATOR),
            'RUBYLIB' => File.join(Overcommit::HOME, 'lib'),
          }
          Overcommit::Utils.with_environment(env) do
            if bundled
              File.write('Gemfile', <<~GEMFILE)
                source 'https://rubygems.org'
                gem 'overcommit', path: #{Overcommit::HOME.inspect}
                gem #{gem_name.inspect}
              GEMFILE
              command('bundle', 'install', '--local')
              config['gemfile'] = 'Gemfile'
            end
            write_config
            successful_cli('--install')
            example.run
          end
        end
      end
    end
  end

  it 'blocks unsigned configuration before any gem code executes' do
    FileUtils.rm_rf(File.join('.git', 'overcommit-signatures'))
    result = commit
    expect(result.status).not_to eq(0)
    expect(result.stdout + result.stderr).to include('No previously recorded signature')
    expect_no_load
  end

  it 'blocks unsigned gem contents even after the configuration is approved' do
    successful_cli('--sign')
    result = commit
    expect(result.status).not_to eq(0)
    expect(result.stdout + result.stderr).to include('Company (gem overcommit-fixture-hooks)',
                                                     'overcommit --sign pre-commit')
    expect_no_load
  end

  it 'lists hooks without executing or activating their gems' do
    successful_cli('--sign')
    result = successful_cli('--list-hooks')
    expect(result.stdout).to include('Company::Check: enabled')
    expect_no_load
  end

  it 'runs installed gem hooks after signing without an existing Bundler context' do
    approve
    result = commit
    expect(result.status).to eq(0), result.stdout + result.stderr
    expect(File.read('hook-ran')).to eq('Company::Check')
    expect(File.exist?('dependency-loaded')).to eq(true)
    expect(File.exist?('entrypoint-loaded')).to eq(true)
  end

  it 'reports unsigned gems cleanly for --run without a stack trace' do
    successful_cli('--sign')
    result = cli('--run')
    expect(result.status).to eq(78)
    expect(result.stdout).to include('overcommit --sign pre-commit')
    expect(result.stderr).to eq('')
    expect_no_load
  end

  {
    'hook code' => 'lib/overcommit/hooks/pre_commit/check.rb',
    'entrypoint code' => 'lib/overcommit_fixture_hooks.rb',
    'unlisted helper code' => 'lib/helper.rb',
    'new files' => 'lib/new_helper.rb',
  }.each do |description, path|
    it "blocks changed #{description} before any gem code runs" do
      approve
      File.open(File.join(@plugin_root, path), 'a') { |file| file.puts("\n# Changed") }
      result = commit
      expect(result.status).not_to eq(0)
      expect(result.stdout + result.stderr).to include('Company (gem overcommit-fixture-hooks)')
      expect_no_load
      successful_cli('--sign', 'pre-commit')
      expect(commit.status).to eq(0)
    end
  end

  it 'blocks changed runtime dependency code before it executes' do
    approve
    File.open(File.join(@dependency_root, 'lib/fixture_helper.rb'), 'a') do |file|
      file.puts("\nFile.write('untrusted-dependency', 'executed')")
    end
    expect(commit.status).not_to eq(0)
    expect_no_load
    expect(File.exist?('untrusted-dependency')).to eq(false)
  end

  it 'requires approval for changed hook settings even after signing the configuration' do
    approve
    config['PreCommit']['Company::Check']['description'] = 'Changed'
    write_config
    successful_cli('--sign')
    expect(commit.status).not_to eq(0)
    expect_no_load
  end

  it 'does not load disabled hooks or try to resolve their missing gems' do
    config['gem_plugins']['Company'] = 'not-installed'
    config['PreCommit']['Company::Check']['enabled'] = false
    write_config
    approve
    expect(commit.status).to eq(0)
    expect_no_load
  end

  it 'never discovers undeclared gems from the load path' do
    config['gem_plugins'] = {}
    config['PreCommit'].delete('Company::Check')
    write_config
    approve
    Overcommit::Utils.with_environment('RUBYLIB' =>
      [File.join(@plugin_root, 'lib'), ENV['RUBYLIB']].join(File::PATH_SEPARATOR)) do
      expect(commit.status).to eq(0)
      expect_no_load
    end
  end

  it 'reports enabled hooks without a declared source' do
    config['gem_plugins'] = {}
    write_config
    successful_cli('--sign')
    result = cli('--sign', 'pre-commit')
    expect(result.status).to eq(78)
    expect(result.stdout).to include('Declare the gem for Company')
    expect_no_load
  end

  it 'reports missing gems without requiring arbitrary entrypoints' do
    config['gem_plugins']['Company'] = 'not-installed'
    write_config
    successful_cli('--sign')
    result = cli('--sign', 'pre-commit')
    expect(result.status).to eq(78)
    expect(result.stdout).to include('Unable to resolve gem plugin not-installed')
    expect_no_load
  end

  it 'reports a missing hook file before loading the gem entrypoint' do
    File.unlink(File.join(@plugin_root, 'lib/overcommit/hooks/pre_commit/check.rb'))
    approve
    result = commit
    expect(result.status).not_to eq(0)
    expect(result.stdout + result.stderr).to include('does not provide Company::Check')
    expect_no_load
  end

  it 'honors ONLY and SKIP with namespaced names without invalidating approvals' do
    approve
    Overcommit::Utils.with_environment('SKIP' => 'Company::Check') do
      expect(commit.status).to eq(0)
      expect(File.exist?('hook-ran')).to eq(false)
    end
    Overcommit::Utils.with_environment('ONLY' => 'Company::Check') do
      expect(commit.status).to eq(0)
      expect(File.read('hook-ran')).to eq('Company::Check')
    end
  end

  it 'keeps built-in, repository, and gem hooks with the same short name separate' do
    FileUtils.mkdir_p('.git-hooks/pre_commit')
    File.write('.git-hooks/pre_commit/check.rb', <<~RUBY)
      module Overcommit::Hook::PreCommit
        class Check < Base
          def run
            File.write('repo-hook-ran', name)
            :pass
          end
        end
      end
    RUBY
    config['PreCommit']['Check'] = { 'enabled' => true, 'requires_files' => false }
    config['PreCommit']['Company::AuthorName'] = { 'enabled' => true, 'requires_files' => false }
    File.write(File.join(@plugin_root, 'lib/overcommit/hooks/pre_commit/author_name.rb'), <<~RUBY)
      module Overcommit::Hook::PreCommit::Company
        class AuthorName < Overcommit::Hook::PreCommit::Base
          def run
            File.write('gem-author-ran', name)
            :pass
          end
        end
      end
    RUBY
    write_config
    command('git', 'add', '.git-hooks')
    approve
    expect(commit.status).to eq(0)
    expect(File.read('repo-hook-ran')).to eq('Check')
    expect(File.read('hook-ran')).to eq('Company::Check')
    expect(File.read('gem-author-ran')).to eq('Company::AuthorName')
  end

  it 'loads the declared gem file even when another load path provides the same path' do
    spoof_root = File.join(@fixture_root, 'spoof')
    spoof_file = File.join(spoof_root, 'overcommit/hooks/pre_commit/check.rb')
    FileUtils.mkdir_p(File.dirname(spoof_file))
    File.write(spoof_file, "File.write('spoof-executed', 'executed'); raise 'spoof'")
    approve
    Overcommit::Utils.with_environment('RUBYLIB' =>
      [spoof_root, ENV['RUBYLIB']].join(File::PATH_SEPARATOR)) do
      expect(commit.status).to eq(0)
      expect(File.exist?('spoof-executed')).to eq(false)
    end
  end

  it 'checks all gem approvals before loading any of their hooks' do
    config['gem_plugins']['Other'] = 'other-fixture-hooks'
    config['PreCommit']['Other::Check'] = { 'enabled' => true, 'requires_files' => false }
    files = { 'lib/overcommit/hooks/pre_commit/check.rb' =>
              "File.write('other-loaded', 'loaded')" }
    other_root = install_fixture('other-fixture-hooks', files)
    write_config
    approve
    File.open(File.join(other_root, 'lib/overcommit/hooks/pre_commit/check.rb'), 'a') do |file|
      file.puts("\n# changed")
    end
    expect(commit.status).not_to eq(0)
    expect_no_load
    expect(File.exist?('other-loaded')).to eq(false)
  end

  it 'loads hooks with the same short name from two different declared gems' do
    config['gem_plugins']['Other'] = 'other-fixture-hooks'
    config['PreCommit']['Other::Check'] = { 'enabled' => true, 'requires_files' => false }
    files = { 'lib/overcommit/hooks/pre_commit/check.rb' =>
              hook_source.gsub('Company', 'Other').gsub('hook-ran', 'other-ran') }
    install_fixture('other-fixture-hooks', files, 'fixture-helper' => '~> 1.0')
    write_config
    approve
    result = commit
    expect(result.status).to eq(0), result.stdout + result.stderr
    expect(File.read('hook-ran')).to eq('Company::Check')
    expect(File.read('other-ran')).to eq('Other::Check')
  end

  it 'checks repository hook approvals before loading an already approved gem' do
    approve
    FileUtils.mkdir_p('.git-hooks/pre_commit')
    File.write('.git-hooks/pre_commit/untrusted.rb', "File.write('repo-loaded', 'loaded')")
    result = commit
    expect(result.status).not_to eq(0)
    expect(result.stdout + result.stderr).to include('Untrusted')
    expect_no_load
    expect(File.exist?('repo-loaded')).to eq(false)
  end

  it 'loads built-in hooks from Overcommit even when the load path contains a competing file' do
    spoof_root = File.join(@fixture_root, 'spoof')
    spoof_file = File.join(spoof_root, 'overcommit/hook/pre_commit/author_name.rb')
    FileUtils.mkdir_p(File.dirname(spoof_file))
    File.write(spoof_file, "File.write('spoof-executed', 'executed'); raise 'spoof'")
    config['PreCommit']['AuthorName'] = { 'enabled' => true }
    write_config
    approve
    Overcommit::Utils.with_environment('RUBYLIB' =>
      [spoof_root, ENV['RUBYLIB']].join(File::PATH_SEPARATOR)) do
      result = commit
      expect(result.status).to eq(0), result.stdout + result.stderr
      expect(File.exist?('spoof-executed')).to eq(false)
    end
  end

  context 'when a gem namespace conflicts with a built-in class' do
    let(:namespace) { 'Base' }

    it 'fails clearly before loading gem code' do
      approve
      result = commit
      expect(result.status).not_to eq(0)
      expect(result.stdout + result.stderr).to include('conflicts with an existing hook')
      expect_no_load
    end
  end

  context 'when the hook constant is not a hook class' do
    let(:hook_source) { 'Overcommit::Hook::PreCommit::Company::Check = 123' }

    it 'reports an invalid subclass without an internal error' do
      approve
      result = commit
      expect(result.status).not_to eq(0)
      expect(result.stdout + result.stderr).to include('not a subclass')
      expect(result.stdout + result.stderr).not_to include('Report this bug')
    end
  end

  context 'when the hook file does not define the requested constant' do
    let(:hook_source) { '# Missing class' }

    it 'reports a hook loading error' do
      approve
      result = cli('--run')
      expect(result.status).to eq(78)
      expect(result.stdout).to include("Unable to load hook 'Company::Check'")
      expect(result.stderr).to eq('')
    end
  end

  context 'with signatures explicitly disabled' do
    before do
      config['verify_signatures'] = false
      write_config
      successful_cli('--sign')
    end

    it 'preserves the existing opt-out behavior' do
      expect(commit.status).to eq(0)
      expect(File.read('hook-ran')).to eq('Company::Check')
    end
  end

  context 'with a configured Gemfile' do
    let(:bundled) { true }

    it 'blocks gem code until both configuration and gem approvals are recorded' do
      successful_cli('--sign')
      expect(commit.status).not_to eq(0)
      expect_no_load
      successful_cli('--sign', 'pre-commit')
      expect_no_load
      result = commit
      expect(result.status).to eq(0), result.stdout + result.stderr
      expect(File.read('hook-ran')).to eq('Company::Check')
    end

    it 'also runs with an explicitly established bundle exec context' do
      approve
      result = command('bundle', 'exec', 'overcommit', '--run')
      expect(result.stdout).to include('Company::Check')
      expect(File.read('hook-ran')).to eq('Company::Check')
    end
  end
end
