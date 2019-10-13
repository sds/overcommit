# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::GoFmt do
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
  before do
    subject.stub(:applicable_files).and_return(files)
  end

  context 'when go fmt exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(success?: true, stderr: '', stdout: '')
      subject.stub(:execute).and_return(result)
    end

    it 'executes go fmt for each file' do
      files.each do |file|
        expect(subject).to receive(:execute).with(subject.command, args: [file]).once
      end
      subject.run
    end

    it 'passes' do
      expect(subject).to pass
    end
  end

  context 'when go fmt exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'when go fmt returns an error to stdout' do
      let(:error_message) { 'some go fmt error' }

      before do
        result.stub(:stdout).and_return(error_message)
        result.stub(:stderr).and_return('')
      end

      it 'executes go fmt for each file' do
        files.each do |file|
          expect(subject).to receive(:execute).with(subject.command, args: [file]).once
        end
        subject.run
      end

      it 'fails' do
        expect(subject).to fail_hook
      end

      it 'returns errors' do
        message = subject.run.last
        expect(message).to eq Array.new(files.count, error_message).join("\n")
      end
    end

    context 'when fo fmt returns an error to stderr' do
      let(:error_message) { 'go: command not found' }
      before do
        result.stub(:stdout).and_return('')
        result.stub(:stderr).and_return(error_message)
      end

      it 'executes go fmt for each file' do
        files.each do |file|
          expect(subject).to receive(:execute).with(subject.command, args: [file]).once
        end
        subject.run
      end

      it 'fails' do
        expect(subject).to fail_hook
      end

      it 'returns valid message' do
        message = subject.run.last
        expect(message).to eq Array.new(files.count, error_message).join("\n")
      end
    end
  end
end
