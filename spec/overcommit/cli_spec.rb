require 'spec_helper'
require 'overcommit/cli'

describe Overcommit::CLI do
  describe '#run' do
    let(:logger) { Overcommit::Logger.silent }
    let(:cli) { described_class.new(arguments, logger) }
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
                                   hash_including(:action => :install))
        subject
      end
    end

    context 'with the uninstall switch specified' do
      let(:arguments) { ['--uninstall'] }

      it 'uninstalls hooks from the current directory' do
        Overcommit::Installer.any_instance.
                              should_receive(:run).
                              with('current-dir',
                                   hash_including(:action => :uninstall))
        subject
      end

      context 'and an explicit target' do
        let(:arguments) { super() + ['target-dir'] }

        it 'uninstalls hooks from the target directory' do
          Overcommit::Installer.any_instance.
                                should_receive(:run).
                                with('target-dir',
                                     hash_including(:action => :uninstall))
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
                                   hash_including(:action => :install))
        subject
      end

      context 'and an explicit target' do
        let(:arguments) { super() + ['target-dir'] }

        it 'installs hooks from the target directory' do
          Overcommit::Installer.any_instance.
                                should_receive(:run).
                                with('target-dir',
                                     hash_including(:action => :install))
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
  end
end
