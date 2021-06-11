# frozen_string_literal: true

require 'spec_helper'

describe 'ad-hoc pre-commit hook' do
  subject do
    hook_loader = Overcommit::HookLoader::PluginHookLoader.new(
      config,
      context,
      Overcommit::Logger.new(STDOUT)
    )
    hooks = hook_loader.load_hooks
    hooks.find { |h| h.name == hook_name }
  end
  let(:config) do
    config = Overcommit::Configuration.new(
      YAML.safe_load(config_contents, [Regexp]), {
        validate: false
      }
    )
    Overcommit::ConfigurationLoader.default_configuration.merge(config)
  end
  let(:context) do
    empty_stdin = File.open(File::NULL) # pre-commit hooks don't take input
    context = Overcommit::HookContext.create('pre-commit', config, applicable_files, empty_stdin)
    context
  end

  around do |example|
    repo do
      example.run
    end
  end

  describe 'if not line-aware' do
    let(:config_contents) do
      <<-'YML'
        PreCommit:
          FooGitHook:
            enabled: true
            command: "foocmd"
      YML
    end
    let(:hook_name) { 'FooGitHook' }
    let(:applicable_files) { nil }

    before do
      context.stub(:execute_hook).with(%w[foocmd]).
        and_return(result)
    end

    context 'when command succeeds' do
      let(:result) do
        double(success?: true, stdout: '')
      end

      it { should pass }
    end

    context 'when command fails' do
      let(:result) do
        double(success?: false, stdout: '', stderr: '')
      end

      it { should fail_hook }
    end
  end
end
