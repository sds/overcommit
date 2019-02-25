# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::CookStyle do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.rb file2.rb])
  end

  context 'when cookstyle exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(success?: true, stderr: '', stdout: '')
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when cookstyle exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    it { should fail_hook }
  end
end
