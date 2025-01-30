# frozen_string_literal: true

require 'spec_helper'
require 'overcommit/cli'
require 'overcommit/hook_context/diff'
require 'overcommit/hook_context/run_all'

describe Overcommit::CLI do
  describe '#run' do
    let(:logger) { Overcommit::Logger.silent }
    let(:input) { double('input') }
    let(:cli) { described_class.new(arguments, input, logger) }
    subject { cli.run }

    before do
      Overcommit::Utils.stub(:repo_root).and_return('current-dir')
    end

    context 'with no arguments' do
      let(:arguments) { [] }

      it 'attempts to install in the current directory' do
        Overcommit::Installer.any_instance.
                              should_receive(:run).
                              with('current-dir',
                                   hash_including(action: :install))
        subject
      end
    end

    context 'with the --list-hooks option specified' do
      let(:arguments) { ['--list-hooks'] }

      let(:contexts) do
        Overcommit::ConfigurationLoader.new(logger).load_repo_config.all_hook_configs.keys
      end

      before { cli.stub(:halt) }

      it 'prints the installed hooks' do
        logger.should_receive(:log).at_least(contexts.count)
        subject
      end
    end

    context 'with the uninstall switch specified' do
      let(:arguments) { ['--uninstall'] }

      it 'uninstalls hooks from the current directory' do
        Overcommit::Installer.any_instance.
                              should_receive(:run).
                              with('current-dir',
                                   hash_including(action: :uninstall))
        subject
      end

      context 'and an explicit target' do
        let(:arguments) { super() + ['target-dir'] }

        it 'uninstalls hooks from the target directory' do
          Overcommit::Installer.any_instance.
                                should_receive(:run).
                                with('target-dir',
                                     hash_including(action: :uninstall))
          subject
        end
      end
    end

    context 'with the install switch specified' do
      let(:arguments) { ['--install'] }

      it 'installs hooks into the current directory' do
        Overcommit::Installer.any_instance.
                              should_receive(:run).
                              with('current-dir',
                                   hash_including(action: :install))
        subject
      end

      context 'and an explicit target' do
        let(:arguments) { super() + ['target-dir'] }

        it 'installs hooks from the target directory' do
          Overcommit::Installer.any_instance.
                                should_receive(:run).
                                with('target-dir',
                                     hash_including(action: :install))
          subject
        end
      end
    end

    context 'with the template directory switch specified' do
      let(:arguments) { ['--template-dir'] }

      before do
        cli.stub(:halt)
      end

      it 'prints the location of the template directory' do
        capture_stdout { subject }.chomp.should end_with 'template-dir'
      end
    end

    context 'with the run switch specified' do
      let(:arguments) { ['--run'] }
      let(:config) { Overcommit::ConfigurationLoader.default_configuration }

      before do
        cli.stub(:halt)
      end

      it 'creates a HookRunner with the run-all context' do
        Overcommit::HookRunner.should_receive(:new).
                               with(config,
                                    logger,
                                    instance_of(Overcommit::HookContext::RunAll),
                                    instance_of(Overcommit::Printer)).
                               and_call_original
        subject
      end

      it 'runs the HookRunner' do
        Overcommit::HookRunner.any_instance.should_receive(:run)
        subject
      end
    end

    context 'with the diff switch specified' do
      let(:arguments) { ['--diff=some-ref'] }
      let(:config) { Overcommit::ConfigurationLoader.default_configuration }

      before do
        cli.stub(:halt)
        Overcommit::HookRunner.any_instance.stub(:run)
      end

      it 'creates a HookRunner with the diff context' do
        Overcommit::HookRunner.should_receive(:new).
          with(config,
               logger,
               instance_of(Overcommit::HookContext::Diff),
               instance_of(Overcommit::Printer)).
          and_call_original
        subject
      end

      it 'runs the HookRunner' do
        Overcommit::HookRunner.any_instance.should_receive(:run)
        subject
      end
    end
  end
end
