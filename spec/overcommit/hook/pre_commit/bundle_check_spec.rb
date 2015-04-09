require 'spec_helper'

describe Overcommit::Hook::PreCommit::BundleCheck do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  context 'when Gemfile.lock is ignored' do
    around do |example|
      repo do
        `touch Gemfile.lock`
        `echo Gemfile.lock > .gitignore`
        `git add .gitignore`
        `git commit -m "Ignore Gemfile.lock"`
        example.run
      end
    end

    it { should pass }
  end

  context 'when Gemfile.lock is not ignored' do
    let(:result) { double('result') }

    around do |example|
      repo do
        example.run
      end
    end

    before do
      result.stub(success?: success, stdout: 'Bundler error message')
      subject.stub(:execute).and_call_original
      subject.stub(:execute).with(%w[bundle check]).and_return(result)
    end

    context 'and bundle check exits unsuccessfully' do
      let(:success) { false }

      it { should fail_hook }
    end

    context 'and bundle check exist successfully' do
      let(:success) { true }

      it { should pass }
    end
  end
end
