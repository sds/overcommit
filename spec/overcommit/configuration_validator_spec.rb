require 'spec_helper'

describe Overcommit::ConfigurationValidator do
  let(:options) { {} }
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
