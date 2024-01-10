# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::PhpCsFixer do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[sample.php])
  end

  context 'when phpcs fixer exits successfully with fixed file' do
    before do
      # rubocop:disable Layout/LineLength
      sample_output = [
        'Loaded config default.',
        'Using cache file ".php_cs.cache".',
        'F',
        'Legend: ?-unknown, I-invalid file syntax, file ignored, S-Skipped, .-no changes, F-fixed, E-error',
        '   1) foo/fixable.php (braces)',
        '',
        'Fixed all files in 0.001 seconds, 10.000 MB memory used',
        '',
      ].join("\n")
      # rubocop:enable Layout/LineLength

      result = double('result')
      result.stub(:status).and_return(0)
      result.stub(:success?).and_return(true)
      result.stub(:stdout).and_return(sample_output)
      subject.stub(:execute).and_return(result)
    end

    it { should warn }
  end

  context 'when phpcs fixer exits successfully with no file to fix' do
    before do
      # rubocop:disable Layout/LineLength
      sample_output = [
        'Loaded config default.',
        'Using cache file ".php_cs.cache".',
        'S',
        'Legend: ?-unknown, I-invalid file syntax, file ignored, S-Skipped, .-no changes, F-fixed, E-error',
        '',
      ].join("\n")
      # rubocop:enable Layout/LineLength

      result = double('result')
      result.stub(:status).and_return(0)
      result.stub(:success?).and_return(true)
      result.stub(:stdout).and_return(sample_output)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when phpcs exits unsuccessfully' do
    before do
      # rubocop:disable Layout/LineLength
      sample_output = [
        'Loaded config default.',
        'Using cache file ".php_cs.cache".',
        'I',
        'Legend: ?-unknown, I-invalid file syntax, file ignored, S-Skipped, .-no changes, F-fixed, E-error',
        'Fixed all files in 0.001 seconds, 10.000 MB memory used',
        '',
        'Files that were not fixed due to errors reported during linting before fixing:',
        '   1) /home/damien/Code/Rezdy/php/foo/broken.php',
        '',
      ].join("\n")
      # rubocop:enable Layout/LineLength

      result = double('result')
      result.stub(:status).and_return(1)
      result.stub(:success?).and_return(false)
      result.stub(:stdout).and_return(sample_output)
      result.stub(:stderr).and_return(sample_output)
      subject.stub(:execute).and_return(result)
    end
    it { should fail_hook }
  end
end
