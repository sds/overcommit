# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Installer do
  let(:logger) { Overcommit::Logger.silent }
  let(:installer) { described_class.new(logger) }

  def hook_files_installed?(hooks_dir)
    Overcommit::Utils.supported_hook_types.all? do |hook_type|
      hook_file = File.join(hooks_dir, hook_type)
      master_hook = File.join(hooks_dir, 'overcommit-hook')
      File.exist?(hook_file) && File.exist?(master_hook) &&
        File.read(hook_file) == File.read(master_hook)
    end
  end

  describe '#run' do
    let(:options) { { action: :install } }
    subject { installer.run(target.to_s, options) }

    context 'when the target is not a directory' do
      let(:target) { Tempfile.new('some-file') }

      it 'raises an error' do
        expect { subject }.to raise_error Overcommit::Exceptions::InvalidGitRepo
      end
    end

    context 'when the target is not a git repo' do
      let(:target) { directory }

      it 'raises an error' do
        expect { subject }.to raise_error Overcommit::Exceptions::InvalidGitRepo
      end
    end

    context 'when the target is a git repo' do
      let(:target) { repo }
      let(:hooks_dir) { File.join(target, '.git', 'hooks') }
      let(:old_hooks_dir) { File.join(hooks_dir, 'old-hooks') }
      let(:master_hook) { File.join(hooks_dir, 'overcommit-hook') }

      context 'and an install is requested' do
        context 'and Overcommit hooks were not previously installed' do
          it 'installs the master hook into the hooks directory' do
            expect { subject }.to change {
              File.file?(master_hook)
            }.from(false).to(true)
          end

          it 'copies all supported hooks from the master hook' do
            expect { subject }.to change {
              hook_files_installed?(hooks_dir)
            }.from(false).to(true)
          end
        end

        context 'and Overcommit hooks were previously installed' do
          before do
            installer.run(target, action: :install)
          end

          it 'keeps the master hook' do
            expect { subject }.to_not change {
              File.file?(master_hook)
            }.from(true)
          end

          it 'maintains all copies of the master hook' do
            expect { subject }.to_not change {
              hook_files_installed?(hooks_dir)
            }.from(true)
          end
        end

        context 'and non-Overcommit hooks were previously installed' do
          let(:old_hooks) { %w[commit-msg pre-commit] }

          before do
            FileUtils.mkdir_p(hooks_dir)
            Dir.chdir(hooks_dir) do
              old_hooks.each { |hook_type| touch(hook_type) }
            end
          end

          it 'does not raise an error' do
            expect { subject }.to_not raise_error
          end

          it 'moves them to a subdirectory' do
            expect { subject }.to change {
              old_hooks.all? do |hook_type|
                File.exist?(File.join(old_hooks_dir, hook_type))
              end
            }.from(false).to(true)
          end

          context 'and the force option is specified' do
            let(:options) { super().merge(force: true) }

            it 'does not raise an error' do
              expect { subject }.to_not raise_error
            end

            it 'copies all supported hooks from the master hook' do
              expect { subject }.to change {
                hook_files_installed?(hooks_dir)
              }.from(false).to(true)
            end
          end
        end

        context 'and a repo configuration file is already present' do
          let(:existing_content) { '# Hello World' }

          around do |example|
            Dir.chdir(target) do
              File.open('.overcommit.yml', 'w') { |f| f.write(existing_content) }
              example.run
            end
          end

          it 'does not overwrite the existing configuration' do
            expect { subject }.to_not change {
              File.open('.overcommit.yml').read
            }.from(existing_content)
          end
        end

        context 'and a repo configuration file is not present' do
          around do |example|
            Dir.chdir(target) do
              example.run
            end
          end

          it 'creates a starter configuration file' do
            expect { subject }.to change {
              File.exist?('.overcommit.yml') && FileUtils.compare_file(
                '.overcommit.yml',
                File.join(Overcommit::HOME, 'config', 'starter.yml')
              )
            }.from(false).to(true)
          end
        end

        context 'and a custom core.hooksPath directory is set' do
          around do |example|
            Dir.chdir(target) do
              FileUtils.mkdir 'my-hooks'
              `git config core.hooksPath my-hooks`
              example.run
            end
          end

          it 'installs the hooks in the custom directory' do
            expect { subject }.to change { hook_files_installed?(File.join(target, 'my-hooks')) }.
                               from(false).
                               to(true)
          end
        end
      end

      context 'and an uninstall is requested' do
        let(:options) { { action: :uninstall } }

        context 'and Overcommit hooks were previously installed' do
          before do
            installer.run(target, action: :install)
          end

          it 'removes the master hook from the hooks directory' do
            expect { subject }.to change {
              File.exist?(master_hook)
            }.from(true).to(false)
          end

          it 'removes all hook files from the hooks directory' do
            expect { subject }.to change {
              hook_files_installed?(hooks_dir)
            }.from(true).to(false)
          end
        end

        context 'and Overcommit hooks were not previously installed' do
          it 'does not raise an error' do
            expect { subject }.to_not raise_error
          end
        end

        context 'and non-Overcommit hooks were previously installed' do
          let(:old_hooks) { %w[commit-msg pre-commit] }

          context 'before installing Overcommit hooks' do
            before do
              FileUtils.mkdir_p(old_hooks_dir)
              Dir.chdir(old_hooks_dir) do
                old_hooks.each { |hook_type| touch(hook_type) }
              end
            end

            it 'restores the previously existing hooks' do
              expect { subject }.to change {
                old_hooks.all? do |hook_type|
                  File.exist?(File.join(hooks_dir, hook_type))
                end
              }.from(false).to(true)
            end
          end

          context 'after installing Overcommit hooks' do
            before do
              FileUtils.mkdir_p(hooks_dir)
              Dir.chdir(hooks_dir) do
                old_hooks.each { |hook_type| touch(hook_type) }
              end
            end

            it 'does not remove the previously existing hooks' do
              expect { subject }.to_not change {
                old_hooks.all? do |hook_type|
                  File.exist?(File.join(hooks_dir, hook_type))
                end
              }.from(true)
            end
          end
        end
      end

      context 'which has an external git dir' do
        let(:submodule) { File.join(target, 'submodule') }
        before do
          system 'git', '-c', 'protocol.file.allow=always', 'submodule', 'add', target,
                 'submodule', chdir: target, out: :close, err: :close
        end
        let(:submodule_git_file) { File.join(submodule, '.git') }
        let(:submodule_git_dir) do
          File.expand_path(File.read(submodule_git_file)[/gitdir: (.*)/, 1], submodule)
        end
        let(:submodule_hooks_dir) { File.join(submodule_git_dir, 'hooks') }

        subject { installer.run(submodule, options) }

        it 'installs hooks into the correct external directory' do
          expect { subject }.to change {
            hook_files_installed?(submodule_hooks_dir)
          }.from(false).to(true)
        end
      end
    end
  end
end
