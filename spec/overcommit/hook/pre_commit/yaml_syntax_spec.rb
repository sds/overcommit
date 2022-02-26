# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::YamlSyntax do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }
  let(:staged_file) { 'file1.yml' }

  before do
    subject.stub(:applicable_files).and_return([staged_file])
  end

  context 'when YAML files have no errors' do
    before do
      YAML.stub(:load_file)
    end

    it { should pass }
  end

  context 'when YAML file has errors' do
    before do
      YAML.stub(:load_file).with(staged_file, { aliases: true }).and_raise(ArgumentError)
      YAML.stub(:load_file).with(staged_file).and_raise(ArgumentError)
    end

    it { should fail_hook }
  end
end
