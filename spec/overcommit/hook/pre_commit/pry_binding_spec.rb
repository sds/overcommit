require 'spec_helper'

describe Overcommit::Hook::PreCommit::PryBinding do
  let(:config)      { Overcommit::ConfigurationLoader.default_configuration }
  let(:context)     { double('context') }
  let(:staged_file) { 'filename.rb' }

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

  context 'when file contains a binding.pry at the begining of the line' do
    let(:contents) { "binding.pry" }

    it { should fail_hook }
  end

  context 'when file contains a binding.pry after any number of spaces' do
    let(:contents) { " binding.pry" }

    it { should fail_hook }
  end

  context 'when file has a line containing but not starting with binding.pry' do
    let(:contents) { '# binding.pry' }

    it { should pass }
  end

  context 'when file does not have any binding.pry' do
    let(:contents) { 'Just some text' }

    it { should pass }
  end
end
