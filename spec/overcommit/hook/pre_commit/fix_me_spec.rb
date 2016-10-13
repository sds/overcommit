require 'spec_helper'

describe Overcommit::Hook::PreCommit::FixMe do
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

  context 'when file contains FIXME' do
    let(:contents) { 'eval(params[:q]) # FIXME maybe this is a bad idea?' }

    it { should warn }
  end

  context 'when file contains TODO with special chars around it' do
    let(:contents) { 'users = (1..1000).map { |i| User.find(1) } #TODO: make it better' }

    it { should warn }
  end

  context 'when file does not contain any FixMe words' do
    let(:contents) { 'if HACKY_CONSTANT.blank?' }

    it { should pass }
  end
end
