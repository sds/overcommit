# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::HookLoader::GemHookLoader do
  let(:hash) { {} }
  let(:config) { Overcommit::Configuration.new(hash) }
  let(:logger) { double('logger') }
  let(:context) { double('context') }
  let(:loader) { described_class.new(config, context, logger) }

  describe '#load_hooks' do
    subject(:load_hooks) { loader.send(:load_hooks) }

    before do
      context.stub(hook_class_name: 'PreCommit',
                   hook_type_name: 'pre_commit')
    end

    it 'loads enabled gem hooks' do
      allow(config).to receive(:enabled_gem_hooks).with(context).and_return(['MyCustomHook'])

      allow(loader).to receive(:require).
        with('overcommit/hook/pre_commit/my_custom_hook').
        and_return(true)
      allow(loader).to receive(:create_hook).with('MyCustomHook')
      expect(loader).to receive(:require).with('overcommit/hook/pre_commit/my_custom_hook')
      load_hooks
    end
  end
end
