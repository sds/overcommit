# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::TsLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[anotherfile.ts])
  end

  context 'when tslint exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    context 'with no output' do
      before do
        result.stub(:stdout).and_return('')
      end

      it { should pass }
    end
  end

  context 'when tslint exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return(
          'src/file/anotherfile.ts[298, 1]: exceeds maximum line length of 140'
        )
      end

      it { should fail_hook }
    end

    context 'and it reports an error with an "ERROR" severity' do
      before do
        result.stub(:stdout).and_return(
          'ERROR: src/AccountController.ts[4, 28]: expected call-signature to have a typedef'
        )
      end

      it { should fail_hook }
    end

    context 'and it reports an warning' do
      before do
        result.stub(:stdout).and_return(
          'WARNING: src/AccountController.ts[4, 28]: expected call-signature to have a typedef'
        )
      end

      it { should warn }
    end
  end
end
