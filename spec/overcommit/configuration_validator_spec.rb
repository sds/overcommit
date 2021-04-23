# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::ConfigurationValidator do
  let(:output) { StringIO.new }
  let(:logger) { Overcommit::Logger.new(output) }
  let(:options) { { logger: logger } }
  let(:config) { Overcommit::Configuration.new(config_hash, validate: false) }
  let(:instance) { described_class.new }

  subject { instance.validate(config, config_hash, options) }

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

  context 'when gem_plugins_require is set' do
    let(:plugins_enabled) { true }
    let(:plugins_require) { nil }

    let(:config_hash) do
      {
        'gem_plugins_enabled' => plugins_enabled,
        'gem_plugins_require' => plugins_require,
      }
    end

    context 'when plugins_enabled is true' do
      let(:plugins_enabled) { true }

      context 'and it is not an array' do
        let(:plugins_require) { true }

        it 'raises an error' do
          expect { subject }.to raise_error Overcommit::Exceptions::ConfigurationError
        end
      end

      context 'and one does not load' do
        let(:plugins_require) { %w[mygem missinggem] }

        before do
          allow(instance).to receive(:require).with('mygem').and_return(true)
          allow(instance).to receive(:require).with('missinggem').and_raise(LoadError)
        end

        it 'raises an error' do
          expect(logger).to receive(:error).with(/installed on the system/)

          expect { subject }.to raise_error Overcommit::Exceptions::ConfigurationError
        end
      end

      context 'and the gems load' do
        let(:plugins_require) { ['mygem'] }

        it 'is valid' do
          expect(instance).to receive(:require).with('mygem').and_return(true)

          expect { subject }.not_to raise_error
        end
      end
    end

    context 'when plugins_enabled is false' do
      let(:plugins_enabled) { false }
      let(:plugins_require) { ['one'] }

      it 'loads nothing' do
        expect(instance).not_to receive(:require)
        subject
      end
    end
  end
end
