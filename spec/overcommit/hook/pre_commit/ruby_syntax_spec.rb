# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::RubySyntax do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.rb file2.rb])
  end

  context 'when ruby_syntax exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    context 'with no errors' do
      before do
        result.stub(:stderr).and_return('')
      end

      it { should pass }
    end
  end

  context 'when ruby_syntax exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:stderr).and_return([
                                          "file1.rb:2: syntax error, unexpected '^'"
                                        ].join("\n"))
      end

      it { should fail_hook }
    end
  end
end
