# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::CodeSpellCheck do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject       { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.rb file2.rb])
  end

  context 'when code-spell-check exists successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      result.stub(:stdout).and_return('')
      result.stub(:stderr).and_return('')
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when code-spell-check exists unsuccessfully via standard error' do
    before do
      result = double('result')
      result.stub(:success?).and_return(false)
      result.stub(:stdout).and_return('')
      result.stub(:stderr).and_return(
        "file1.rb:35: inkorrectspelling\n✗ Errors in code spellchecking"
      )
      subject.stub(:execute).and_return(result)
    end

    it { should fail_hook }
  end
end
