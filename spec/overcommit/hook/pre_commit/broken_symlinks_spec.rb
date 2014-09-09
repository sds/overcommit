require 'spec_helper'

describe Overcommit::Hook::PreCommit::BrokenSymlinks do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  let(:staged_file) { 'staged-file.txt' }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return([staged_file])
  end

  before do
    Overcommit::Utils.stub(:broken_symlink?).with(staged_file).and_return(broken)
  end

  context 'when the symlink is broken' do
    let(:broken) { true }

    it { should fail_hook }
  end

  context 'when the symlink is not broken' do
    let(:broken) { false }

    it { should pass }
  end
end
