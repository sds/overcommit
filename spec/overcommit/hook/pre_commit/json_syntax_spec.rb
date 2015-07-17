require 'spec_helper'
require 'json'

describe Overcommit::Hook::PreCommit::JsonSyntax do
  let(:config)      { Overcommit::ConfigurationLoader.default_configuration }
  let(:context)     { double('context') }
  let(:staged_file) { 'my_file.json' }

  subject           { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return([staged_file])
  end

  around do |example|
    repo do
      touch staged_file
      `git add #{staged_file}`
      example.run
    end
  end

  context 'when JSON files have no errors' do
    before do
      JSON.stub(:parse)
    end

    it { should pass }
  end

  context 'when JSON file has errors' do
    before do
      JSON.stub(:parse).and_raise(JSON::ParserError)
    end

    it { should fail_hook }
  end
end
