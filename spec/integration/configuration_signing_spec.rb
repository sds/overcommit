require 'spec_helper'
require 'yaml'

describe 'configuration file signing' do
  let(:enable_verification) { true }
  let(:new_verify_signatures) { verify_signatures }

  let(:config) do
    {
      'verify_signatures' => verify_signatures,
      'CommitMsg' => {
        'ALL' => { 'enabled' => false },
      },
      'PreCommit' => {
        'ALL' => { 'enabled' => false },
      },
    }
  end

  let(:new_config) do
    config.dup.tap do |conf|
      conf['verify_signatures'] = new_verify_signatures
    end
  end

  subject { shell(%w[git commit --allow-empty -m Test]) }

  around do |example|
    repo do
      echo(config.to_yaml, '.overcommit.yml')
      `overcommit --install > #{File::NULL}`

      `overcommit --sign` if configuration_signed
      echo(new_config.to_yaml, '.overcommit.yml')

      example.run
    end
  end

  context 'when verify_signatures is true' do
    let(:verify_signatures) { true }

    context 'and the configuration has not been signed' do
      let(:configuration_signed) { false }

      it 'reports a signature error' do
        subject.status.should_not == 0
      end
    end

    context 'and the configuration has been signed' do
      let(:configuration_signed) { true }

      it 'does not report a signature error' do
        subject.status.should == 0
      end

      context 'and verify_signatures was changed to false' do
        let(:new_verify_signatures) { false }

        it 'reports a signature error' do
          subject.status.should_not == 0
        end
      end
    end
  end

  context 'when verify_signatures is false' do
    let(:verify_signatures) { false }

    context 'and the configuration has not been signed' do
      let(:configuration_signed) { false }

      it 'reports a signature error' do
        subject.status.should_not == 0
      end
    end

    context 'and the configuration has been signed' do
      let(:configuration_signed) { true }

      it 'does not report a signature error' do
        subject.status.should == 0
      end

      context 'and verify_signatures was changed to true' do
        let(:new_verify_signatures) { true }

        it 'reports a signature error' do
          subject.status.should_not == 0
        end
      end
    end
  end
end
