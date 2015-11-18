require 'spec_helper'

describe Overcommit::ConfigurationValidator do
  let(:options) { {} }
  subject { described_class.new.validate(config, options) }

  context 'when hook has an invalid name' do
    let(:config) do
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
end
