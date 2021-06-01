# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::Pronto do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.rb file2.rb])
  end

  context 'when pronto exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when pronto exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return([
          'file2.rb:10 E: IDENTICAL code found in :iter.',
        ].join("\n"))
      end

      it { should fail_hook }
    end

    context 'and it reports a warning' do
      before do
        result.stub(:stdout).and_return <<~MESSAGE
          Running Pronto::Rubocop
          file1.rb:12 W: Line is too long. [107/80]
          file2.rb:14 I: Prefer single-quoted strings

          ```suggestion
          x = 'x'
          ```
        MESSAGE
      end

      it { should warn }
    end
  end
end
