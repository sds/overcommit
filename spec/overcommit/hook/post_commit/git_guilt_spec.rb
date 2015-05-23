require 'spec_helper'

describe Overcommit::Hook::PostCommit::GitGuilt do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  context 'when git-guilt exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
      subject.stub(initial_commit?: false, execute: result)
    end

    context 'with no output' do
      before do
        result.stub(:stdout).and_return('')
      end

      it { should pass }
    end

    context 'with output' do
      before do
        result.stub(:stdout).and_return('GitGuilt Tester +++')
      end

      it { should warn }
    end
  end

  context 'when git-guilt exits unsuccessfully' do
    before do
      result = double('result')
      result.stub(success?: false, stderr: '')
      subject.stub(initial_commit?: false, execute: result)
    end

    it { should fail_hook }
  end

  context 'when there is no previous commit' do
    before do
      context.stub(:initial_commit?).and_return(true)
    end

    it { should pass }
  end
end
