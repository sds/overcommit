# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::ConfigurationValidator do
  let(:output) { StringIO.new }
  let(:logger) { Overcommit::Logger.new(output) }
  let(:options) { { logger: logger } }
  let(:config) { Overcommit::Configuration.new(config_hash, validate: false) }

  subject { described_class.new.validate(config, config_hash, options) }

  context 'when hook has an invalid name' do
    let(:config_hash) do
      {
        'PreCommit' => {
          'My_Hook' => {
            'enabled' => false,
          },
        },
      }
    end

    it 'raises an error' do
      expect { subject }.to raise_error Overcommit::Exceptions::ConfigurationError
    end
  end

  context 'when hook has `env` set' do
    let(:config_hash) do
      {
        'PreCommit' => {
          'MyHook' => {
            'enabled' => true,
            'env' => env,
          },
        },
      }
    end

    context 'and it is a single string' do
      let(:env) { 'OVERCOMMIT_ENV_VAR=1' }

      it 'raises an error and mentions `env` must be a hash' do
        expect { subject }.to raise_error Overcommit::Exceptions::ConfigurationError
        output.string.should =~ /must be a hash/i
      end
    end

    context 'and it is a hash with string values' do
      let(:env) { { 'OVERCOMMIT_ENV_VAR' => '1', 'OVERCOMMIT_ENV_VAR_2' => '2' } }

      it 'is valid' do
        expect { subject }.not_to raise_error
      end
    end

    context 'and it is a hash with integer values' do
      let(:env) { { 'OVERCOMMIT_ENV_VAR' => 1, 'OVERCOMMIT_ENV_VAR_2' => 2 } }

      it 'raises an error' do
        expect { subject }.to raise_error Overcommit::Exceptions::ConfigurationError
        output.string.should =~ /`OVERCOMMIT_ENV_VAR`.*must be a string/i
        output.string.should =~ /`OVERCOMMIT_ENV_VAR_2`.*must be a string/i
      end
    end

    context 'and it is a hash with boolean values' do
      let(:env) { { 'OVERCOMMIT_ENV_VAR' => true, 'OVERCOMMIT_ENV_VAR_2' => false } }

      it 'raises an error' do
        expect { subject }.to raise_error Overcommit::Exceptions::ConfigurationError
        output.string.should =~ /`OVERCOMMIT_ENV_VAR`.*must be a string/i
        output.string.should =~ /`OVERCOMMIT_ENV_VAR_2`.*must be a string/i
      end
    end
  end

  context 'when hook has `processors` set' do
    let(:concurrency) { 4 }

    let(:config_hash) do
      {
        'concurrency' => concurrency,
        'PreCommit' => {
          'MyHook' => {
            'enabled' => true,
            'processors' => processors,
          },
        },
      }
    end

    context 'and it is larger than `concurrency`' do
      let(:processors) { concurrency + 1 }

      it 'raises an error' do
        expect { subject }.to raise_error Overcommit::Exceptions::ConfigurationError
      end
    end

    context 'and it is equal to `concurrency`' do
      let(:processors) { concurrency }

      it 'is valid' do
        expect { subject }.not_to raise_error
      end
    end

    context 'and it is less than `concurrency`' do
      let(:processors) { concurrency - 1 }

      it 'is valid' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
