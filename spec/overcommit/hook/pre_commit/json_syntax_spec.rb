# frozen_string_literal: true

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
      Overcommit::Utils.execute(['git', 'add', '--', staged_file])
      example.run
    end
  end

  context 'when JSON files have no errors' do
    before do
      File.write(staged_file, '{"valid": true}')
    end

    it { should pass }
  end

  it 'reads a pipe-prefixed filename literally' do
    skip 'Windows filenames cannot contain pipes' if Overcommit::OS.windows?

    file = '|echo injected'
    File.write(file, '{"literal": true}')
    subject.stub(:applicable_files).and_return([file])
    expect(subject.run).to eq([])
  end

  it 'reports a missing file without executing a command' do
    subject.stub(:applicable_files).and_return(['|echo injected'])
    expect { subject.run }.to raise_error(SystemCallError)
  end

  context 'when JSON file has errors' do
    before do
      File.write(staged_file, '{invalid JSON}')
    end

    it { should fail_hook }
  end
end
