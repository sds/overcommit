require 'spec_helper'

describe Overcommit::Hook::PreCommit::TrailingWhitespace do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }
  let(:staged_file) { 'filename.txt' }

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

  context 'when file contains trailing whitespace' do
    let(:contents) { 'Some trailing whitespace   ' }

    it { should fail_check }
  end

  context 'when file contains trailing tabs' do
    let(:contents) { "Some trailing tabs\t\t" }

    it { should fail_check }
  end

  context 'when file has no invalid whitespace' do
    let(:contents) { 'Just some text' }

    it { should pass }
  end
end
