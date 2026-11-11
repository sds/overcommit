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
    around do |example|
      directory { example.run }
    end

    before { add_file    'COMMIT_EDITMSG', '' }
    after  { remove_file 'COMMIT_EDITMSG' }

    context 'when the checked out branch matches the pattern' do
      before { checkout_branch '123-topic' }
      before { hook.run }

      it { is_expected.to pass }

      it 'prepends the replacement text' do
        expect(File.read('COMMIT_EDITMSG')).to eq("[#123]\n")
      end

      context 'when the replacement text contains a space' do
        let(:config) { new_config('replacement_text' => '[\1] ') }

        it 'prepends the replacement text, including the space' do
          expect(File.read('COMMIT_EDITMSG')).to eq("[123] \n")
        end
      end

      context 'when skip_if exits with a zero status' do
        let(:config) { new_config('skip_if' => ['bash', '-c', 'exit 0']) }

        it { is_expected.to pass }

        it 'does not change the commit message' do
          expect(File.read('COMMIT_EDITMSG')).to eq("\n")
        end
      end

      context 'when skip_if exits with a non-zero status' do
        let(:config) { new_config('skip_if' => ['bash', '-c', 'exit 1']) }

        it { is_expected.to pass }

        it 'does change the commit message' do
          expect(File.read('COMMIT_EDITMSG')).to eq("[#123]\n")
        end
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

    context 'when the message is given and the branch matches the pattern' do
      let(:replacement_text) { '[#\1] ' }
      let(:config) do
        new_config('replacement_text' => replacement_text, 'skipped_commit_types' => [])
      end
      subject(:hook) { hook_for(config, message_context) }

      before do
        checkout_branch '123-topic'
        add_file 'COMMIT_EDITMSG', message
        hook.run
      end

      context 'when the message does not start with the replacement text' do
        let(:message) { 'Fix login' }

        it 'prepends the replacement text' do
          expect(File.read('COMMIT_EDITMSG')).to eq("[#123] Fix login\n")
        end
      end

      context 'when the message already starts with the replacement text' do
        let(:message) { '[#123] Fix login' }

        it 'does not prepend the replacement text again' do
          expect(File.read('COMMIT_EDITMSG')).to eq("[#123] Fix login\n")
        end
      end

      context 'when the message starts with the replacement text without its trailing space' do
        let(:message) { '[#123]Fix login' }

        it 'does not prepend the replacement text again' do
          expect(File.read('COMMIT_EDITMSG')).to eq("[#123]Fix login\n")
        end
      end

      context 'when the message starts with the replacement text after blank lines' do
        let(:message) { "\n\n[#123] Fix login" }

        it 'does not prepend the replacement text again' do
          expect(File.read('COMMIT_EDITMSG')).to eq("\n\n[#123] Fix login\n")
        end
      end

      context 'when the message contains the replacement text after its start' do
        let(:message) { 'Revert "[#123] Fix login"' }

        it 'prepends the replacement text' do
          expect(File.read('COMMIT_EDITMSG')).to eq(%{[#123] Revert "[#123] Fix login"\n})
        end
      end

      %w[fixup squash amend].each do |autosquash_prefix|
        context "when the message starts with `#{autosquash_prefix}! `" do
          let(:message) { "#{autosquash_prefix}! [#123] Fix login" }

          it 'keeps the autosquash prefix at the start' do
            expect(File.read('COMMIT_EDITMSG')).to eq("#{message}\n")
          end
        end
      end

      context 'when the replacement text ends in a word character' do
        let(:replacement_text) { '#\1 ' }

        context 'when the message starts with the same ID' do
          let(:message) { '#123 Fix login' }

          it 'does not prepend the replacement text again' do
            expect(File.read('COMMIT_EDITMSG')).to eq("#123 Fix login\n")
          end
        end

        context 'when the message starts with a longer ID' do
          let(:message) { '#1234 Fix login' }

          it 'prepends the replacement text' do
            expect(File.read('COMMIT_EDITMSG')).to eq("#123 #1234 Fix login\n")
          end
        end
      end

      context 'when the replacement text is only whitespace' do
        let(:replacement_text) { ' ' }
        let(:message) { 'Fix login' }

        it 'prepends the replacement text' do
          expect(File.read('COMMIT_EDITMSG')).to eq(" Fix login\n")
        end
      end
    end

    context 'when the message is not valid UTF-8' do
      let(:config) do
        new_config('replacement_text' => '[#\1] ', 'skipped_commit_types' => [])
      end
      subject(:hook) { hook_for(config, message_context) }

      before do
        checkout_branch '123-topic'
        File.binwrite('COMMIT_EDITMSG', "\xC4nderung".b)

        # The locale sets the encoding that `File.read` returns. Use UTF-8, the
        # usual locale, because `lstrip` raises on invalid UTF-8 but not on
        # invalid US-ASCII.
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with('COMMIT_EDITMSG') do |name|
          File.binread(name).force_encoding(Encoding::UTF_8)
        end
      end

      it 'prepends the replacement text' do
        expect(hook.run).to eq(:pass)
        expect(File.binread('COMMIT_EDITMSG')).to eq("[#123] \xC4nderung".b)
      end
    end

    context 'with the ticket ID config from the hook documentation' do
      let(:config) do
        new_config(
          'branch_pattern' => '\A.*?([A-Z][A-Z0-9]+-\d+).*\z',
          'replacement_text' => '[\1] ',
          'skipped_commit_types' => %w[template merge squash],
          'on_warn' => 'pass',
        )
      end
      let(:branch) { 'task/PROJ-123/fix-login' }
      let(:message) { 'Fix login' }
      let(:hook_context) { message_context }
      subject(:hook) { hook_for(config, hook_context) }

      before do
        checkout_branch branch
        add_file 'COMMIT_EDITMSG', message
      end

      context 'when the message is given on a branch with a ticket ID' do
        it 'prepends the ticket ID' do
          expect(hook.run_and_transform).to eq([:pass, nil])
          expect(File.read('COMMIT_EDITMSG')).to eq("[PROJ-123] Fix login\n")
        end
      end

      context 'when amending a commit that already has the ticket ID' do
        let(:message) { '[PROJ-123] Fix login' }
        let(:hook_context) { commit_context }

        it 'keeps one ticket ID' do
          expect(hook.run_and_transform).to eq([:pass, nil])
          expect(File.read('COMMIT_EDITMSG')).to eq("[PROJ-123] Fix login\n")
        end
      end

      %w[template merge squash].each do |commit_type|
        context "when the commit type is `#{commit_type}`" do
          let(:hook_context) { public_send("#{commit_type}_context") }

          it 'does not change the commit message' do
            expect(hook.run_and_transform).to eq([:pass, nil])
            expect(File.read('COMMIT_EDITMSG')).to eq("Fix login\n")
          end
        end
      end

      context 'when the branch has no ticket ID' do
        let(:branch) { 'main' }

        it 'passes without a warning and does not change the commit message' do
          expect(hook.run_and_transform).to eq([:pass, nil])
          expect(File.read('COMMIT_EDITMSG')).to eq("Fix login\n")
        end
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

  it 'recognizes an exact prefix that ends in a word character' do
    allow(hook).to receive(:new_template).and_return('PROJ-12 ')
    expect(hook.keep_message?('PROJ-12')).to eq(true)
  end

  it 'uses the default pattern when the configured pattern is absent' do
    allow(hook).to receive(:config).and_return(hook.config.merge('branch_pattern' => nil))
    expect(hook.branch_pattern).to eq(described_class::DEFAULT_BRANCH_PATTERN)
  end
end
