require 'spec_helper'

describe Overcommit::Installer do
  let(:logger) { Overcommit::Logger.silent }
  let(:installer) { described_class.new(logger) }

  describe '#run' do
    let(:options) { { :action => :install } }
    let(:subject) { installer.run(target, options) }

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

      context 'and an install is requested' do
        context 'and Overcommit hooks were not previously installed' do
          it 'installs the master hook into the hooks directory' do
            subject
            File.file?(File.join(hooks_dir, 'overcommit-hook')).should be_true
          end

          it 'symlinks all supported hooks to the master hook' do
            subject
            Overcommit::Utils.supported_hook_types.all? do |hook_type|
              File.readlink(File.join(hooks_dir, hook_type)) == 'overcommit-hook'
            end
          end
        end

        context 'and Overcommit hooks were previously installed' do
          before do
            installer.run(target, :action => :install)
          end

          it 'keeps the master hook' do
            expect { subject }.to_not change {
              File.file?(File.join(hooks_dir, 'overcommit-hook')).should be_true
            }
          end

          it 'maintains all symlinks to the master hook' do
            expect { subject }.to_not change {
              Overcommit::Utils.supported_hook_types.all? do |hook_type|
                File.readlink(File.join(hooks_dir, hook_type)) == 'overcommit-hook'
              end
            }
          end
        end

        context 'and non-Overcommit hooks were previously installed' do
          before do
            Dir.chdir(hooks_dir) do
              FileUtils.touch('commit-msg')
              FileUtils.touch('pre-commit')
            end
          end

          it 'raises an error' do
            expect { subject }.to raise_error Overcommit::Exceptions::PreExistingHooks
          end

          context 'and the force option is specified' do
            let(:options) { super().merge(:force => true) }

            it 'does not raise an error' do
              expect { subject }.to_not raise_error
            end
          end
        end
      end

      context 'and an uninstall is requested' do
        let(:options) { { :action => :uninstall } }

        context 'and Overcommit hooks were previously installed' do
          before do
            installer.run(target, :action => :install)
          end

          it 'removes the master hook from the hooks directory' do
            expect { subject }.to change {
              File.exists?(File.join(hooks_dir, 'overcommit-hook'))
            }.from(true).to(false)
          end

          it 'removes all symlinks from the hooks directory' do
            expect { subject }.to change {
              Overcommit::Utils.supported_hook_types.all? do |hook_type|
                File.exists?(File.join(hooks_dir, hook_type))
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
          before do
            Dir.chdir(hooks_dir) do
              FileUtils.touch('commit-msg')
              FileUtils.touch('pre-commit')
            end
          end

          it 'does not remove the previously existing hooks' do
            expect { subject }.to_not change {
              %w[commit-msg pre-commit].all? do |hook_type|
                File.exists?(File.join(hooks_dir, hook_type))
              end
            }
          end
        end
      end
    end
  end
end
