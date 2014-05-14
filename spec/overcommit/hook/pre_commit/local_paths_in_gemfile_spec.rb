require 'spec_helper'

describe Overcommit::Hook::PreCommit::LocalPathsInGemfile do
  let(:config)      { Overcommit::ConfigurationLoader.default_configuration }
  let(:context)     { double('context') }
  let(:staged_file) { 'Gemfile' }

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

  context 'when file contains a local path in Ruby 1.8 hash syntax format' do
    let(:contents) { "gem 'fuubar', :path => '../fuubar'" }

    it { should warn }
  end

  context 'when file contains a local path on its own line in Ruby 1.8 hash syntax format' do
    let(:contents) { ":path => '../fuubar'" }

    it { should warn }
  end

  context 'when file contains a local path starting with leading spaces in Ruby 1.8 hash format' do
    let(:contents) { " :path => '../fuubar'" }

    it { should warn }
  end

  context 'when file contains a local path in Ruby 1.9 hash syntax format' do
    let(:contents) { "gem 'fuubar', path: '../fuubar'" }

    it { should warn }
  end

  context 'when file contains local path on its own line in Ruby 1.9 hash syntax format' do
    let(:contents) { "path: '../fuubar'" }

    it { should warn }
  end

  context 'when file contains local path starting with leading spaces in Ruby 1.9 hash format' do
    let(:contents) { " path: '../fuubar'" }

    it { should warn }
  end

  context 'when the file does not contain a local path' do
    let(:contents) { "gem 'fuubar'" }

    it { should pass }
  end
end
