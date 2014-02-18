require 'spec_helper'

describe Overcommit::Hook::PreCommit::BundleCheck do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  context 'when bundler is not installed' do
    before do
      subject.stub(:in_path?).and_return(false)
    end

    it { should warn }
  end

  context 'when Gemfile.lock is ignored' do
    around do |example|
      repo do
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
      result.stub(:success? => success, :stdout => 'Bundler error message')
      subject.stub(:command).and_call_original
      subject.stub(:command).with('bundle check').and_return(result)
    end

    context 'and bundle check exits unsuccessfully' do
      let(:success) { false }

      it { should fail_check }
    end

    context 'and bundle check exist successfully' do
      let(:success) { true }

      it { should pass }
    end
  end
end
