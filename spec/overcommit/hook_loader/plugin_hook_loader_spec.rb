# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::HookLoader::PluginHookLoader do
  subject(:hook) { loader.load_hooks.find { |loaded| loaded.name == 'CustomScript' } }

  let(:loader) { described_class.new(config, context, Overcommit::Logger.silent) }
  let(:config) do
    Overcommit::ConfigurationLoader.default_configuration.merge(
      Overcommit::Configuration.new(
        'PreCommit' => { 'CustomScript' => hook_config.merge(config_changes) }
      )
    )
  end
  let(:hook_config) { { 'enabled' => true, 'command' => %w[custom-script] } }
  let(:context) { Overcommit::HookContext.create('pre-commit', config, [], StringIO.new) }
  let(:config_changes) { {} }
  let(:result) { double(success?: false, stdout: stdout, stderr: '') }
  let(:stdout) { "file.foo:2: warning: check this\n" }

  around do |example|
    repo { example.run }
  end

  after do
    hook_module = Overcommit::Hook::PreCommit
    if hook_module.const_defined?(:CustomScript, false)
      hook_module.send(:remove_const, :CustomScript)
    end
  end

  context 'without a message pattern' do
    before do
      allow(context).to receive(:execute_hook).with(%w[custom-script]).and_return(result)
    end

    it 'preserves the exit status and both output streams for existing Git hooks' do
      allow(result).to receive(:stderr).and_return('stderr detail')
      expect(hook.run).to eq([:fail, "#{stdout}stderr detail"])
    end

    it 'passes when the command succeeds' do
      allow(result).to receive(:success?).and_return(true)
      expect(hook.run).to eq(:pass)
    end
  end

  context 'with a message pattern' do
    let(:hook_config) do
      super().merge(
        'message_pattern' => /^(?<file>(?:\w:)?[^:]+):(?<line>\d+): (?<type>\w+):/,
        'warning_message_type_pattern' => /^warn(?:ing)?$/i,
        'flags' => ['--format=emacs'],
        'include' => '**/*.foo',
        'exclude' => 'excluded.foo'
      )
    end

    before do
      allow(context).to receive(:modified_files).
        and_return(%w[file.foo excluded.foo other.txt].map { |file| File.expand_path(file) })
      allow(context).to receive(:modified_lines_in_file).with('file.foo').and_return([2])
      allow(hook).to receive(:execute).
        with(%w[custom-script --format=emacs], args: [File.expand_path('file.foo')]).
        and_return(result)
    end

    it 'extracts file, line, type, and original message using configured regexes' do
      expect(hook.run).to eq([
        Overcommit::Hook::Message.new(:warning, 'file.foo', 2, stdout.chomp)
      ])
    end

    it 'preserves Windows drive letters in diagnostic paths' do
      allow(result).to receive(:stdout).and_return("C:/project/file.foo:2: warning: check this\n")
      expect(hook.run.first.file).to eq('C:/project/file.foo')
    end

    it 'fails on errors on modified lines' do
      allow(result).to receive(:stdout).and_return("file.foo:2: error: fix this\n")
      status, output = hook.run_and_transform
      expect(status).to eq(:fail)
      expect(output).to include('Errors on modified lines:', 'fix this')
    end

    it 'warns on warning messages' do
      expect(hook.run_and_transform.first).to eq(:warn)
    end

    it 'keeps errors and warnings distinct in mixed output' do
      allow(result).to receive(:stdout).and_return("#{stdout}file.foo:2: error: fix this\n")
      expect(hook.run.map(&:type)).to eq([:warning, :error])
      expect(hook.run_and_transform.first).to eq(:fail)
    end

    it 'passes on a successful exit even without output' do
      allow(result).to receive_messages(success?: true, stdout: '')
      expect(hook.run).to eq(:pass)
    end

    it 'fails when the command fails without stdout, preserving stderr' do
      allow(result).to receive_messages(stdout: '', stderr: 'command crashed')
      expect(hook.run_and_transform).to eq([:fail, 'command crashed'])
    end

    it 'fails when the command fails silently' do
      allow(result).to receive(:stdout).and_return('')
      expect(hook.run_and_transform.first).to eq(:fail)
    end

    it 'fails when stdout contains only blank lines' do
      allow(result).to receive(:stdout).and_return("\n\n")
      expect(hook.run_and_transform.first).to eq(:fail)
    end

    it 'reports unexpected output rather than silently discarding it' do
      allow(result).to receive(:stdout).and_return('unrecognized diagnostic')
      expect { hook.run }.to raise_error(Overcommit::Exceptions::MessageProcessingError)
    end

    context 'with a literal warning string' do
      let(:config_changes) { { 'warning_message_type_pattern' => 'warn' } }

      it 'classifies warnings by substring' do
        expect(hook.run.first.type).to eq(:warning)
      end
    end

    context 'without a warning pattern' do
      let(:hook_config) { super().reject { |key, _| key == 'warning_message_type_pattern' } }

      it 'defaults to errors' do
        expect(hook.run.first.type).to eq(:error)
      end
    end

    context 'with a file-only pattern' do
      let(:config_changes) { { 'message_pattern' => /^(?<file>(?:\w:)?[^:]+):/ } }

      it 'supports missing line and type captures' do
        message = hook.run.first
        expect([message.file, message.line, message.type]).to eq(['file.foo', nil, :error])
      end
    end

    context 'with an unmatched optional type capture' do
      let(:config_changes) do
        { 'message_pattern' => /^(?<file>(?:\w:)?[^:]+):(?<line>\d+):(?: (?<type>error):)?/ }
      end

      it 'defaults to an error' do
        expect(hook.run.first.type).to eq(:error)
      end
    end

    context 'with required_executable in place of command' do
      let(:hook_config) do
        super().reject { |key, _| key == 'command' }.
          merge('required_executable' => 'custom-script')
      end

      it 'executes the configured executable' do
        expect(hook.run.first.file).to eq('file.foo')
      end
    end

    it 'does not run when requires_files is set and no files match' do
      allow(context).to receive(:modified_files).and_return([File.expand_path('other.txt')])
      expect(hook.run?).to eq(false)
    end

    context 'with errors on unmodified lines' do
      let(:stdout) { "file.foo:1: error: old problem\n" }

      it 'fails by default' do
        expect(hook.run_and_transform.first).to eq(:fail)
      end

      context 'when configured to warn about problems' do
        let(:config_changes) { { 'problem_on_unmodified_line' => 'warn' } }

        it 'warns' do
          expect(hook.run_and_transform.first).to eq(:warn)
        end
      end

      context 'when configured to report problems' do
        let(:config_changes) { { 'problem_on_unmodified_line' => 'report' } }

        it 'fails' do
          expect(hook.run_and_transform.first).to eq(:fail)
        end
      end

      context 'when configured to ignore problems' do
        let(:config_changes) { { 'problem_on_unmodified_line' => 'ignore' } }

        it 'passes and omits ignored problems' do
          expect(hook.run_and_transform).to eq([:pass, ''])
        end
      end
    end
  end

  context 'with invalid line-aware options' do
    let(:config_changes) { { 'message_pattern' => pattern } }

    context 'when message_pattern is a string' do
      let(:pattern) { 'not a Ruby regexp' }

      it 'reports a configuration error' do
        expect { hook }.to raise_error(Overcommit::Exceptions::HookLoadError, /message_pattern/)
      end
    end

    context 'when message_pattern has no file capture' do
      let(:pattern) { /(?<line>\d+)/ }

      it 'explains the required capture' do
        expect { hook }.to raise_error(Overcommit::Exceptions::HookLoadError, /file/)
      end
    end

    context 'when warning_message_type_pattern is not a string or regexp' do
      let(:config_changes) do
        { 'message_pattern' => /(?<file>.+)/, 'warning_message_type_pattern' => true }
      end

      it 'explains the invalid option' do
        expect { hook }.to raise_error(Overcommit::Exceptions::HookLoadError,
                                       /warning_message_type_pattern/)
      end
    end
  end

  it 'runs a real command against staged files and processes its diagnostics' do
    File.write('file.foo', "first line\nsecond line\n")
    Overcommit::Utils.execute(%w[git add file.foo])
    hook_config.merge!(
      'command' => [RbConfig.ruby, '-e', 'puts ARGV.first + ":2: warning: check this"; exit 1',
                    '--'],
      'message_pattern' => /^(?<file>(?:\w:)?[^:]+):(?<line>\d+): (?<type>\w+):/,
      'warning_message_type_pattern' => /^warning$/
    )
    status, output = hook.run_and_transform
    expect(status).to eq(:warn)
    expect(output).to include('Warnings on modified lines:', 'file.foo:2: warning: check this')
  end

  it 'uses the current configuration when reloading the same hook name' do
    loader.load_hooks
    updated_config = config.merge(
      Overcommit::Configuration.new(
        'PreCommit' => { 'CustomScript' => { 'message_pattern' => /^(?<file>(?:\w:)?[^:]+):/ } }
      )
    )
    updated_loader = described_class.new(updated_config, context, Overcommit::Logger.silent)
    reloaded = updated_loader.load_hooks.find { |loaded| loaded.name == 'CustomScript' }
    allow(reloaded).to receive(:execute).and_return(result)
    expect(reloaded.run.first.file).to eq('file.foo')
  end
end
