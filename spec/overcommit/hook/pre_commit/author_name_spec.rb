# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::AuthorName do
  let(:config) { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }
  let(:result) { double('result') }

  shared_examples_for 'author name check' do
    context 'when user has no name' do
      let(:name) { '' }

      it { should fail_hook }
    end

    context 'when user has only a first name' do
      let(:name) { 'John' }

      it { should pass }
    end

    context 'when user has first and last name' do
      let(:name) { 'John Doe' }

      it { should pass }
    end
  end

  context 'when name is set via config' do
    before do
      result.stub(:stdout).and_return(name)
      subject.stub(:execute).and_return(result)
    end

    it_should_behave_like 'author name check'
  end

  context 'when name is set via environment variable' do
    around do |example|
      Overcommit::Utils.with_environment 'GIT_AUTHOR_NAME' => name do
        example.run
      end
    end

    it_should_behave_like 'author name check'
  end
end
