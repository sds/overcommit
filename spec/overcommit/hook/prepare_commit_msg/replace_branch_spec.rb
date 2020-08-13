# frozen_string_literal: true

require 'spec_helper'
require 'overcommit/hook_context/prepare_commit_msg'

describe Overcommit::Hook::PrepareCommitMsg::ReplaceBranch do
  def checkout_branch(branch)
    allow(Overcommit::GitRepo).to receive(:current_branch).and_return(branch)
  end

  def new_config(opts = {})
    default = Overcommit::ConfigurationLoader.default_configuration

    return default if opts.empty?

    default.merge(
      Overcommit::Configuration.new(
        'PrepareCommitMsg' => {
          'ReplaceBranch' => opts.merge('enabled' => true)
        }
      )
    )
  end

  def new_context(config, argv)
    Overcommit::HookContext::PrepareCommitMsg.new(config, argv, StringIO.new)
  end

  def hook_for(config, context)
    described_class.new(config, context)
  end

  def add_file(name, contents)
    File.open(name, 'w') { |f| f.puts contents }
  end

  def remove_file(name)
    File.delete(name)
  end

  before { allow(Overcommit::Utils).to receive_message_chain(:log, :debug) }

  let(:config)           { new_config }
  let(:normal_context)   { new_context(config, ['COMMIT_EDITMSG']) }
  let(:message_context)  { new_context(config, %w[COMMIT_EDITMSG message]) }
  let(:commit_context)   { new_context(config, %w[COMMIT_EDITMSG commit HEAD]) }
  let(:merge_context)    { new_context(config, %w[MERGE_MSG merge]) }
  let(:squash_context)   { new_context(config, %w[SQUASH_MSG squash]) }
  let(:template_context) { new_context(config, ['template.txt', 'template']) }
  subject(:hook)         { hook_for(config, normal_context) }

  describe '#run' do
    before { add_file    'COMMIT_EDITMSG', '' }
    after  { remove_file 'COMMIT_EDITMSG' }

    context 'when the checked out branch matches the pattern' do
      before { checkout_branch '123-topic' }
      before { hook.run }

      it { is_expected.to pass }

      it 'prepends the replacement text' do
        expect(File.read('COMMIT_EDITMSG')).to eq("[#123]\n")
      end
    end

    context "when the checked out branch doesn't matches the pattern" do
      before { checkout_branch 'topic-123' }
      before { hook.run }

      context 'with the default `skipped_commit_types`' do
        it { is_expected.to warn }
      end

      context 'when merging, and `skipped_commit_types` includes `merge`' do
        let(:config)   { new_config('skipped_commit_types' => ['merge']) }
        subject(:hook) { hook_for(config, merge_context) }

        it { is_expected.to pass }
      end

      context 'when merging, and `skipped_commit_types` includes `template`' do
        let(:config)   { new_config('skipped_commit_types' => ['template']) }
        subject(:hook) { hook_for(config, template_context) }

        it { is_expected.to pass }
      end

      context 'when merging, and `skipped_commit_types` includes `message`' do
        let(:config)   { new_config('skipped_commit_types' => ['message']) }
        subject(:hook) { hook_for(config, message_context) }

        it { is_expected.to pass }
      end

      context 'when merging, and `skipped_commit_types` includes `commit`' do
        let(:config)   { new_config('skipped_commit_types' => ['commit']) }
        subject(:hook) { hook_for(config, commit_context) }

        it { is_expected.to pass }
      end

      context 'when merging, and `skipped_commit_types` includes `squash`' do
        let(:config)   { new_config('skipped_commit_types' => ['squash']) }
        subject(:hook) { hook_for(config, squash_context) }

        it { is_expected.to pass }
      end
    end

    context 'when the replacement text points to a valid filename' do
      before { checkout_branch '123-topic' }
      before { add_file    'replacement_text.txt', 'FOO' }
      after  { remove_file 'replacement_text.txt' }

      let(:config) { new_config('replacement_text' => 'replacement_text.txt') }
      let(:normal_context) { new_context(config, ['COMMIT_EDITMSG']) }
      subject(:hook)       { hook_for(config, normal_context) }

      before { hook.run }

      it { is_expected.to pass }

      let(:commit_msg) { File.read('COMMIT_EDITMSG') }

      it 'uses the file contents as the replacement text' do
        expect(commit_msg).to eq(File.read('replacement_text.txt'))
      end
    end
  end
end
