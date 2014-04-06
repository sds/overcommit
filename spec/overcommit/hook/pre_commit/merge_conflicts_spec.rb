require 'spec_helper'

describe Overcommit::Hook::PreCommit::MergeConflicts do
  let(:config)      { Overcommit::ConfigurationLoader.default_configuration }
  let(:context)     { double('context') }
  let(:staged_file) { 'filename.txt' }

  subject           { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return([staged_file])
  end

  around do |example|
    repo do
      File.open(staged_file, 'w') { |f| f.write(contents) }
      `git add #{staged_file}`
      example.run
    end
  end

  context 'when file contains a merge conflict marker' do
    let(:contents) { "Just\n<<<<<<<some\nconflicting text" }

    it { should fail_hook }
  end

  context 'when file does not have any merge conflict markers' do
    let(:contents) { 'Just some text' }

    it { should pass }
  end
end
