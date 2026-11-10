# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::Sorbet do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.rb file2.rb])
  end

  context 'when Sorbet exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }

    context 'and it printed a message to stderr' do
      before do
        result.stub(:stderr).and_return("No errors! Great job.\n")
      end

      it { should pass }
    end
  end

  context 'when Sorbet exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:stderr).and_return(normalize_indent(<<-MSG))
            sorbet.rb:1: Method `foo` does not exist on `T.class_of(Bar)` https://srb.help/7003
            5 |  foo 'bar'
                      ^^^
            Errors: 1
        MSG
      end

      it { should fail_hook }
    end
  end
end
