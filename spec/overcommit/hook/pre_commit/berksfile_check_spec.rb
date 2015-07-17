require 'spec_helper'

describe Overcommit::Hook::PreCommit::BerksfileCheck do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  context 'when Berksfile.lock is ignored' do
    around do |example|
      repo do
        touch 'Berksfile.lock'
        echo('Berksfile.lock', '.gitignore')
        `git add .gitignore`
        `git commit -m "Ignore Berksfile.lock"`
        example.run
      end
    end

    it { should pass }
  end

  context 'when Berksfile.lock is not ignored' do
    let(:result) { double('result') }

    around do |example|
      repo do
        example.run
      end
    end

    before do
      result.stub(success?: success, stderr: 'Berkshelf error message')
      subject.stub(:execute).and_call_original
      subject.stub(:execute).with(%w[berks list --quiet]).and_return(result)
    end

    context 'and `berks list` exits unsuccessfully' do
      let(:success) { false }

      it { should fail_hook }
    end

    context 'and `berks list` exits successfully' do
      let(:success) { true }

      it { should pass }
    end
  end
end
