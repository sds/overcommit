# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::YamlLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  let(:applicable_files) { %w[file1.yaml file2.yml] }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(applicable_files)
  end

  around do |example|
    repo do
      example.run
    end
  end

  before do
    subject.stub(:execute).with(%w[yamllint --format=parsable --strict], args: applicable_files).
      and_return(result)
  end

  context 'and has 2 suggestions for line length' do
    let(:result) do
      double(
        success?: false,
        stdout: <<-MSG
file1.yaml:3:81: [error] line too long (253 > 80 characters) (line-length)
file2.yml:41:81: [error] line too long (261 > 80 characters) (line-length)
        MSG
      )
    end

    it { should fail_hook }
  end

  context 'and has 1 error and 1 warning' do
    let(:result) do
      double(
        success?: false,
        stdout: <<-MSG
file1.yaml:3:81: [error] line too long (253 > 80 characters) (line-length)
file2.yml:41:81: [warning] missing document start "---" (document-start)
        MSG
      )
    end

    it { should fail_hook }
  end
  context 'and has single suggestion for missing file header' do
    let(:result) do
      double(
        success?: false,
        stdout: <<-MSG
file1.yaml:1:1: [warning] missing document start "---" (document-start)
        MSG
      )
    end

    it { should warn }
  end

  context 'and does not have any suggestion' do
    let(:result) do
      double(success?: true, stdout: '')
    end

    it { should pass }
  end
end
