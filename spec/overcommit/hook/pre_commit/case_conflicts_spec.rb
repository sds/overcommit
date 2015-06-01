require 'spec_helper'

describe Overcommit::Hook::PreCommit::CaseConflicts do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    Overcommit::GitRepo.stub(:initial_commit?).and_return(false)
    Overcommit::GitRepo.stub(:list_files).and_return(%w[foo])
  end

  context 'when a new file conflicts with an existing file' do
    before do
      subject.stub(:applicable_files).and_return(%w[Foo])
    end

    it { should fail_hook }
  end

  context 'when a new file conflicts with another new file' do
    before do
      subject.stub(:applicable_files).and_return(%w[bar Bar])
    end

    it { should fail_hook }
  end

  context 'when there are no conflicts' do
    before do
      subject.stub(:applicable_files).and_return(%w[bar baz])
    end

    it { should pass }
  end
end
