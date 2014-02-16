require 'spec_helper'

describe Overcommit::Hook::PreCommit::AuthorEmail do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }
  let(:result)  { double('result') }

  before do
    result.stub(:stdout).and_return(email)
    subject.stub(:command).and_return(result)
  end

  context 'when user has no email' do
    let(:email) { '' }

    it { should fail_check }
  end

  context 'when user has an invalid email' do
    let(:email) { 'Invalid Email' }

    it { should fail_check }
  end

  context 'when user has a valid email' do
    let(:email) { 'email@example.com' }

    it { should pass }
  end

  context 'when a custom pattern is specified' do
    let(:config) do
      super().merge(Overcommit::Configuration.new(
        'pre_commit' => {
          'AuthorEmail' => {
            'pattern' => '^[^@]+@causes\.com$'
          }
        }
      ))
    end

    context 'and the email does not match the pattern' do
      let(:email) { 'email@example.com' }

      it { should fail_check }
    end

    context 'and the email matches the pattern' do
      let(:email) { 'email@causes.com' }

      it { should pass }
    end
  end
end
