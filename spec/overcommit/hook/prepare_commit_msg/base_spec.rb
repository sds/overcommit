require 'spec_helper'
require 'overcommit/hook_context/prepare_commit_msg'

describe Overcommit::Hook::PrepareCommitMsg::Base do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { Overcommit::HookContext::PrepareCommitMsg.new(config, [], StringIO.new) }
  let(:printer) { double('printer') }

  context 'when multiple hooks run simultaneously' do
    let(:hook_1) { described_class.new(config, context) }
    let(:hook_2) { described_class.new(config, context) }

    let(:tempfile) { 'test-prepare-commit-msg.txt' }

    let(:initial_content) { "This is a test\n" }

    before do
      File.open(tempfile, 'w') do |f|
        f << initial_content
      end
    end

    after do
      File.delete(tempfile)
    end

    it 'works well with concurrency' do
      allow(context).to receive(:commit_message_filename).and_return(tempfile)
      allow(hook_1).to receive(:run) do
        hook_1.modify_commit_message do |contents|
          "alpha\n" + contents
        end
      end
      allow(hook_2).to receive(:run) do
        hook_2.modify_commit_message do |contents|
          contents + "bravo\n"
        end
      end
      Thread.new { hook_1.run }
      Thread.new { hook_2.run }
      Thread.list.each { |t| t.join unless t == Thread.current }
      expect(File.read(tempfile)).to match(/alpha\n#{initial_content}bravo\n/m)
    end
  end
end
