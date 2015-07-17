require 'spec_helper'

describe Overcommit::Installer do
  let(:logger) { Overcommit::Logger.silent }
  let(:installer) { described_class.new(logger) }

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

      context 'and an install is requested' do
        context 'and Overcommit hooks were not previously installed' do
          it 'installs the master hook into the hooks directory' do
            expect { subject }.to change {
              File.file?(File.join(hooks_dir, 'overcommit-hook'))
            }.from(false).to(true)
          end

          it 'symlinks all supported hooks to the master hook' do
            expect { subject }.to change {
              Overcommit::Utils.supported_hook_types.all? do |hook_type|
                hook_file = File.join(hooks_dir, hook_type)
                Overcommit::Utils::FileUtils.symlink?(hook_file) &&
                  Overcommit::Utils::FileUtils.readlink(hook_file) == 'overcommit-hook'
              end
            }.from(false).to(true)
          end
        end

        context 'and Overcommit hooks were previously installed' do
          before do
            installer.run(target, action: :install)
          end

          it 'keeps the master hook' do
            expect { subject }.to_not change {
              File.file?(File.join(hooks_dir, 'overcommit-hook'))
            }.from(true)
          end

          it 'maintains all symlinks to the master hook' do
            expect { subject }.to_not change {
              Overcommit::Utils.supported_hook_types.all? do |hook_type|
                hook_file = File.join(hooks_dir, hook_type)
                Overcommit::Utils::FileUtils.symlink?(hook_file) &&
                  Overcommit::Utils::FileUtils.readlink(hook_file) == 'overcommit-hook'
              end
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

            it 'symlinks all supported hooks to the master hook' do
              expect { subject }.to change {
                Overcommit::Utils.supported_hook_types.all? do |hook_type|
                  hook_file = File.join(hooks_dir, hook_type)
                  Overcommit::Utils::FileUtils.symlink?(hook_file) &&
                    Overcommit::Utils::FileUtils.readlink(hook_file) == 'overcommit-hook'
                end
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
      end

      context 'and an uninstall is requested' do
        let(:options) { { action: :uninstall } }

        context 'and Overcommit hooks were previously installed' do
          before do
            installer.run(target, action: :install)
          end

          it 'removes the master hook from the hooks directory' do
            expect { subject }.to change {
              File.exist?(File.join(hooks_dir, 'overcommit-hook'))
            }.from(true).to(false)
          end

          it 'removes all symlinks from the hooks directory' do
            expect { subject }.to change {
              Overcommit::Utils.supported_hook_types.all? do |hook_type|
                hook_file = File.join(hooks_dir, hook_type)
                Overcommit::Utils::FileUtils.symlink?(hook_file) &&
                  Overcommit::Utils::FileUtils.readlink(hook_file) == 'overcommit-hook'
              end
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
    end
  end
end
