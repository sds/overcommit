# frozen_string_literal: true

require 'spec_helper'

describe 'Vale pre-commit command hook' do
  subject(:hook) { loader.load_hooks.find { |loaded| loaded.name == 'Vale' } }

  let(:loader) do
    Overcommit::HookLoader::PluginHookLoader.new(config, context, Overcommit::Logger.silent)
  end
  let(:config) do
    Overcommit::ConfigurationLoader.default_configuration.merge(
      Overcommit::Configuration.new('PreCommit' => { 'Vale' => options })
    )
  end
  let(:options) { { 'enabled' => true } }
  let(:context) { Overcommit::HookContext.create('pre-commit', config, [], StringIO.new) }
  let(:stdout) { "README.md:2:7:Test.Spelling:Use 'Overcommit'.\n" }
  let(:result) { double(success?: false, stdout: stdout, stderr: '') }

  around do |example|
    repo { example.run }
  end

  after do
    if Overcommit::Hook::PreCommit.const_defined?(:Vale, false)
      Overcommit::Hook::PreCommit.send(:remove_const, :Vale)
    end
  end

  it 'is disabled by default' do
    default_config = Overcommit::ConfigurationLoader.default_configuration
    default_loader = Overcommit::HookLoader::PluginHookLoader.new(
      default_config, context, Overcommit::Logger.silent
    )
    expect(default_loader.load_hooks.map(&:name)).not_to include('Vale')
  end

  it 'can be enabled using only configuration' do
    expect(config.enabled_ad_hoc_hooks(context)).to include('Vale')
    expect(config.enabled_builtin_hooks(context)).not_to include('Vale')
    expect(hook.command).to eq(%w[vale --output=line])
    expect(hook.description).to eq('Check spelling and style with Vale')
  end

  it 'selects staged text, markup, and source files, respecting exclusions' do
    options['exclude'] = 'vendor/**'
    paths = %w[README.md docs/guide.adoc index.html notes.txt src/main.rb vendor/old.md image.png]
    allow(context).to receive(:modified_files).
      and_return(paths.map { |path| File.expand_path(path) })
    expect(hook.applicable_files).to eq(
      paths.first(5).map { |path| File.expand_path(path) }.sort
    )
  end

  it 'allows projects to override the file selection' do
    options['include'] = '**/*.custom'
    allow(context).to receive(:modified_files).
      and_return(%w[README.md prose.custom].map { |path| File.expand_path(path) })
    expect(hook.applicable_files).to eq([File.expand_path('prose.custom')])
  end

  it 'skips when no staged files match' do
    allow(context).to receive(:modified_files).and_return([File.expand_path('image.png')])
    expect(hook.run?).to eq(false)
  end

  it 'reports how to install Vale when the executable is missing' do
    allow(hook).to receive(:in_path?).with('vale').and_return(false)
    expect(hook).not_to receive(:execute)
    status, output = hook.run_and_transform
    expect(status).to eq(:fail)
    expect(output).to include("'vale' is not installed", 'brew install vale')
  end

  context 'when running Vale' do
    before do
      allow(context).to receive(:modified_files).and_return([File.expand_path('README.md')])
      allow(context).to receive(:modified_lines_in_file).with('README.md').and_return([2])
      allow(hook).to receive(:in_path?).with('vale').and_return(true)
      allow(hook).to receive(:execute).
        with(%w[vale --output=line], args: [File.expand_path('README.md')]).and_return(result)
    end

    it 'passes on a successful exit' do
      allow(result).to receive_messages(success?: true, stdout: '')
      expect(hook.run_and_transform.first).to eq(:pass)
    end

    it 'extracts file and line and preserves the complete Vale diagnostic' do
      expect(hook.run).to eq([
        Overcommit::Hook::Message.new(:error, 'README.md', 2, stdout.chomp)
      ])
    end

    it 'fails on diagnostics on modified lines' do
      status, output = hook.run_and_transform
      expect(status).to eq(:fail)
      expect(output).to include('Errors on modified lines:', stdout.chomp)
    end

    it 'preserves spaces, Windows drive letters, and backslashes in paths' do
      path = 'C:\\project docs\\README.md'
      allow(result).to receive(:stdout).and_return("#{path}:2:7:Test.Spelling:Fix this.\n")
      expect(hook.run.first.file).to eq(path)
      expect(hook.run.first.line).to eq(2)
    end

    it 'extracts all diagnostics, including messages containing colons' do
      second = "docs/guide.md:8:1:Test.Style:Prefer this: example.\n"
      allow(result).to receive(:stdout).and_return(stdout + second)
      expect(hook.run.map { |message| [message.file, message.line, message.content] }).to eq([
        ['README.md', 2, stdout.chomp], ['docs/guide.md', 8, second.chomp]
      ])
    end

    it 'fails when Vale exits unsuccessfully without stdout, preserving stderr' do
      allow(result).to receive_messages(stdout: '', stderr: 'E100: missing .vale.ini')
      expect(hook.run_and_transform).to eq([:fail, 'E100: missing .vale.ini'])
    end

    it 'fails when Vale exits unsuccessfully without any output' do
      allow(result).to receive(:stdout).and_return('')
      expect(hook.run_and_transform.first).to eq(:fail)
    end

    it 'reports unexpected stdout instead of discarding it' do
      allow(result).to receive(:stdout).and_return('unexpected Vale output')
      expect { hook.run }.to raise_error(Overcommit::Exceptions::MessageProcessingError)
    end

    it 'treats diagnostics without severity as errors even if the message mentions a warning' do
      allow(result).to receive(:stdout).
        and_return("README.md:2:7:Test.Style:A warning: fix this.\n")
      expect(hook.run.first.type).to eq(:error)
    end

    context 'with diagnostics on unmodified lines' do
      let(:stdout) { "README.md:1:1:Test.Style:Old problem.\n" }

      it 'fails by default' do
        expect(hook.run_and_transform.first).to eq(:fail)
      end

      context 'when configured to ignore them' do
        let(:options) { super().merge('problem_on_unmodified_line' => 'ignore') }

        it 'passes and omits the diagnostic' do
          expect(hook.run_and_transform).to eq([:pass, ''])
        end
      end

      context 'when configured to warn' do
        let(:options) { super().merge('problem_on_unmodified_line' => 'warn') }

        it 'warns' do
          expect(hook.run_and_transform.first).to eq(:warn)
        end
      end
    end
  end

  it 'supports a custom output template that includes severity' do
    options.merge!(
      'flags' => ['--output=./vale.tmpl'],
      'message_pattern' => /^(?<file>(?:\w:)?[^:]+):(?<line>\d+):\d+: \[(?<type>\w+)\]/,
      'warning_message_type_pattern' => 'warning'
    )
    allow(hook).to receive(:execute).with(%w[vale --output=./vale.tmpl], args: []).
      and_return(double(success?: false,
                        stdout: "README.md:2:7: [warning] Test.Style:Fix this.\n"))
    expect(hook.run.first.type).to eq(:warning)
  end

  it 'runs a real subprocess with the default flags and matching staged file paths' do
    File.write('guide with spaces.md', "first line\nsecond line\n")
    File.write('image.png', 'image')
    Overcommit::Utils.execute(['git', 'add', 'guide with spaces.md', 'image.png'])
    options['command'] = [RbConfig.ruby, '-e', <<~RUBY, '--']
      abort 'wrong arguments' unless ARGV == ['--output=line', File.expand_path('guide with spaces.md')]
      puts ARGV.last + ":2:1:Test.Style:Fix this."
      exit 1
    RUBY
    allow(hook).to receive(:in_path?).with('vale').and_return(true)
    status, output = hook.run_and_transform
    expect(status).to eq(:fail)
    expect(output).to include('Errors on modified lines:',
                              'guide with spaces.md:2:1:Test.Style:Fix this.')
  end
end
