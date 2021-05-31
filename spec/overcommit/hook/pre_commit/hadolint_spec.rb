# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::Hadolint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  let(:applicable_files) { %w[Dockerfile Dockerfile.web] }
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
    subject.stub(:execute).with(%w[hadolint], args: Array(applicable_files.first)).
      and_return(result_dockerfile)
    subject.stub(:execute).with(%w[hadolint], args: Array(applicable_files.last)).
      and_return(result_dockerfile_web)
  end

  context 'and has 2 suggestions' do
    let(:result_dockerfile) do
      double(
        success?: false,
        stdout: <<-MSG
Dockerfile:5 DL3015 Avoid additional packages by specifying `--no-install-recommends`
        MSG
      )
    end
    let(:result_dockerfile_web) do
      double(
        success?: false,
        stdout: <<-MSG
Dockerfile.web:13 DL3020 Use COPY instead of ADD for files and folders
        MSG
      )
    end

    it { should fail_hook }
  end

  context 'and has single suggestion for double quote' do
    let(:result_dockerfile) do
      double(
        success?: false,
        stdout: <<-MSG
Dockerfile:11 SC2086 Double quote to prevent globbing and word splitting.
        MSG
      )
    end
    let(:result_dockerfile_web) do
      double(success?: true, stdout: '')
    end

    it { should fail_hook }
  end

  context 'and does not have any suggestion' do
    let(:result_dockerfile) do
      double(success?: true, stdout: '')
    end
    let(:result_dockerfile_web) do
      double(success?: true, stdout: '')
    end

    it { should pass }
  end
end
