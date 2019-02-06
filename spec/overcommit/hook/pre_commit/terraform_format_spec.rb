# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::TerraformFormat do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.tf file2.tf])
  end

  context 'when Terraform exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when Terraform exits unsucessfully' do
    let(:result_ok) { double('result') }
    let(:result_bad) { double('result') }
    let(:cmdline) { %w[terraform fmt -check=true -diff=false] }

    before do
      result_ok.stub(:success?).and_return(true)
      result_bad.stub(:success?).and_return(false)
      subject.stub(:execute).with(cmdline, args: ['file1.tf']).and_return(result_ok)
      subject.stub(:execute).with(cmdline, args: ['file2.tf']).and_return(result_bad)
    end

    it { should fail_hook }
  end
end
