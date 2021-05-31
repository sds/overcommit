# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PrePush::RakeTarget do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  context 'without targets parameters' do
    let(:result) { double('result') }
    it 'raises' do
      expect { subject.run }.to raise_error(
        RuntimeError, /RakeTarget: targets parameter is empty.*/
      )
    end
  end

  context 'with targets parameter set' do
    let(:config) do
      super().merge(Overcommit::Configuration.new(
                      'PrePush' => {
                        'RakeTarget' => {
                          'targets' => ['test'],
                        }
                      }
      ))
    end
    let(:result) { double('result') }

    context 'when rake exits successfully' do
      before do
        result.stub(:success?).and_return(true)
        subject.stub(:execute).and_return(result)
        result.stub(:stdout).and_return('ANYTHING')
      end

      it { should pass }
    end

    context 'when rake exits unsuccessfully' do
      before do
        result.stub(:success?).and_return(false)
        subject.stub(:execute).and_return(result)
        result.stub(:stdout).and_return('ANYTHING')
      end

      it { should fail_hook }
    end
  end
end
