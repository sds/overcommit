# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::PhpLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(['sample.php'])
  end

  context 'when php lint exits successfully' do
    before do
      result = double('result')
      result.stub(:status).and_return(0)
      result.stub(:success?).and_return(true)
      result.stub(:stdout).and_return('No syntax errors detected in sample.php')
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when php lint exits unsuccessfully' do
    before do
      # php -l prints the same to both stdout and stderr
      # rubocop:disable Layout/LineLength
      sample_output = [
        '',
        "Parse error: syntax error, unexpected '0' (T_LNUMBER), expecting variable (T_VARIABLE) or '{' or '$' in sample.php on line 3 ",
        'Errors parsing invalid.php',
      ].join("\n")
      # rubocop:enable Layout/LineLength

      result = double('result')
      result.stub(:status).and_return(255)
      result.stub(:success?).and_return(false)
      result.stub(:stdout).and_return(sample_output)
      result.stub(:stderr).and_return(sample_output)
      subject.stub(:execute).and_return(result)
    end

    it { should fail_hook }
  end
end
