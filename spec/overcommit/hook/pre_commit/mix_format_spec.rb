# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::MixFormat do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.ex file2.exs])
  end

  context 'when mix format exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when mix format exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return('')
        result.stub(:stderr).and_return([
          '** (Mix) mix format failed due to --check-formatted.',
          'The following files are not formatted:',
          '',
          '  * lib/file1.ex',
          '  * lib/file2.ex'
        ].join("\n"))
      end

      it { should fail_hook }
    end
  end
end
