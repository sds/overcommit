# frozen_string_literal: true

require 'spec_helper'
require 'rexml/document'

describe Overcommit::Hook::PreCommit::XmlSyntax do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }
  let(:staged_file) { 'file1.xml' }

  before do
    subject.stub(:applicable_files).and_return([staged_file])
  end

  around do |example|
    repo { example.run }
  end

  it 'reads a pipe-prefixed filename literally' do
    skip 'Windows filenames cannot contain pipes' if Overcommit::OS.windows?

    file = '|echo injected'
    File.write(file, '<root/>')
    subject.stub(:applicable_files).and_return([file])
    expect(subject.run).to eq([])
  end

  it 'reports a missing file without executing a command' do
    subject.stub(:applicable_files).and_return(['|echo injected'])
    expect { subject.run }.to raise_error(SystemCallError)
  end

  context 'when XML files have no errors' do
    before do
      File.write(staged_file, '<root/>')
    end

    it { should pass }
  end

  context 'when XML file has errors' do
    before do
      File.write(staged_file, '<root></wrong>')
    end

    it { should fail_hook }
  end
end
