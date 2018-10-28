# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::PhpStan do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[sample.php])
  end

  context 'when phpstan exits successfully' do
    before do
      sample_output = ''

      result = double('result')
      result.stub(:success?).and_return(true)
      result.stub(:stdout).and_return(sample_output)
      result.stub(:status).and_return(0)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when phpstan exits unsuccessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      result.stub(:status).and_return(2)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports a warning' do
      before do
        sample_output = [
          '/sample1.php:14:Call to an undefined static method Sample1::where()',
          '/sample2.php:17:Anonymous function has an unused use $myVariable.'
        ].join("\n")
        result.stub(:stdout).and_return(sample_output)
      end

      it { should fail_hook }
    end
  end
end
