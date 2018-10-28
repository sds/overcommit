# frozen_string_literal: true

require 'spec_helper'
require 'rexml/document'

describe Overcommit::Hook::PreCommit::XmlSyntax do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }
  let(:staged_file) { 'file1.xml' }

  before do
    IO.stub(:read).with(staged_file)
    subject.stub(:applicable_files).and_return([staged_file])
  end

  context 'when XML files have no errors' do
    before do
      REXML::Document.stub(:new)
    end

    it { should pass }
  end

  context 'when XML file has errors' do
    before do
      REXML::Document.stub(:new).and_raise(REXML::ParseException.new(''))
    end

    it { should fail_hook }
  end
end
