# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Installer, 'updating installed hooks' do
  let(:logger) { Overcommit::Logger.silent }
  let(:installer) { described_class.new(logger) }

  it 'replaces outdated hooks with the current master hook' do
    repo do
      path = Dir.pwd
      installer.run(path, action: :install)
      master = File.join(Overcommit::GitConfig.hooks_path, 'overcommit-hook')
      File.write(master, 'old master')
      expect(installer.run(path, action: :update)).to eq(true)
      expect(File.read(master)).to eq(File.read(described_class::MASTER_HOOK))
    end
  end

  it 'does not rewrite hooks that are already current' do
    repo do
      path = Dir.pwd
      installer.run(path, action: :install)
      expect(logger).not_to receive(:success)
      expect(installer.run(path, action: :update)).to be_nil
    end
  end

  it 'rejects a foreign hook introduced after old hooks were preserved' do
    repo do
      path = Dir.pwd
      allow(installer).to receive(:preserve_old_hooks)
      File.write(File.join(Overcommit::GitConfig.hooks_path, 'pre-commit'), '# foreign hook')
      expect { installer.run(path, action: :install) }.
        to raise_error(Overcommit::Exceptions::PreExistingHooks, /pre-commit/)
    end
  end
end
