# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::GolangciLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  let(:files) do
    %w[
      pkg1/file1.go
      pkg1/file2.go
      pkg2/file1.go
      file1.go
    ]
  end
  let(:packages) { %w[pkg1 pkg2 .] }
  before do
    subject.stub(:applicable_files).and_return(files)
  end

  context 'when golangci-lint exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(success?: true, stderr: '', stdout: '')
      subject.stub(:execute).and_return(result)
    end

    it 'passes packages to golangci-lint' do
      expect(subject).to receive(:execute).with(subject.command, args: packages)
      subject.run
    end

    it 'passes' do
      expect(subject).to pass
    end
  end

  context 'when golangci-lint exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'when golangci-lint returns an error' do
      let(:error_message) do
        'pkg1/file1.go:8:6: exported type `Test` should have comment or be unexported (golint)'
      end

      before do
        result.stub(:stdout).and_return(error_message)
        result.stub(:stderr).and_return('')
      end

      it 'passes packages to golangci-lint' do
        expect(subject).to receive(:execute).with(subject.command, args: packages)
        subject.run
      end

      it 'fails' do
        expect(subject).to fail_hook
      end

      it 'returns valid message' do
        message = subject.run.last
        expect(message.file).to eq 'pkg1/file1.go'
        expect(message.line).to eq 8
        expect(message.content).to eq error_message
      end
    end

    context 'when a generic error message is written to stderr' do
      let(:error_message) { 'golangci-lint: command not found' }
      before do
        result.stub(:stdout).and_return('')
        result.stub(:stderr).and_return(error_message)
      end

      it 'passes packages to golangci-lint' do
        expect(subject).to receive(:execute).with(subject.command, args: packages)
        subject.run
      end

      it 'fails' do
        expect(subject).to fail_hook
      end

      it 'returns valid message' do
        message = subject.run.last
        expect(message).to eq error_message
      end
    end
  end
end
