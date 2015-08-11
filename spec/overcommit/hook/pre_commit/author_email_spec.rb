require 'spec_helper'

describe Overcommit::Hook::PreCommit::AuthorEmail do
  let(:config) { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }
  let(:result) { double('result') }

  before do
    result.stub(:stdout).and_return(email)
    subject.stub(:execute).and_return(result)
  end

  context 'when user has no email' do
    let(:email) { '' }

    it { should fail_hook }
  end

  context 'when user has an invalid email' do
    let(:email) { 'Invalid Email' }

    it { should fail_hook }
  end

  context 'when user has a valid email' do
    let(:email) { 'email@example.com' }

    it { should pass }
  end

  context 'when a custom pattern is specified' do
    let(:config) do
      super().merge(Overcommit::Configuration.new(
        'PreCommit' => {
          'AuthorEmail' => {
            'pattern' => '^[^@]+@brigade\.com$'
          }
        }
      ))
    end

    context 'and the email does not match the pattern' do
      let(:email) { 'email@example.com' }

      it { should fail_hook }
    end

    context 'and the email matches the pattern' do
      let(:email) { 'email@brigade.com' }

      it { should pass }
    end
  end
end
