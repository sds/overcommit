# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::LineEndings do
  let(:config) do
    Overcommit::ConfigurationLoader.default_configuration.merge(
      Overcommit::Configuration.new(
        'PreCommit' => {
          'LineEndings' => {
            'eol' => eol
          }
        }
      )
    )
  end

  let(:context) { double('context') }
  subject { described_class.new(config, context) }
  let(:eol) { "\n" }
  let(:staged_file) { 'filename.txt' }

  before do
    skip('Skip LineEndings tests for Git < 2.10') if Overcommit::GIT_VERSION < '2.10'
    subject.stub(:applicable_files).and_return([staged_file])
  end

  around do |example|
    repo do
      File.open(staged_file, 'w') { |f| f.write(contents) }
      `git add "#{staged_file}" > #{File::NULL} 2>&1`
      example.run
    end
  end

  context 'when file path contains spaces' do
    let!(:staged_file) { 'a file with spaces.txt' }
    let(:contents) { "test\n" }

    it { should_not fail_hook }
  end

  context 'when enforcing \n' do
    context 'when file contains \r\n line endings' do
      let(:contents) { "CR-LF\r\nline\r\nendings\r\n" }

      it { should fail_hook }
    end

    context 'when file contains \n endings' do
      let(:contents) { "LF\nline\nendings\n" }

      it { should pass }
    end
  end

  context 'when enforcing \r\n' do
    let(:eol) { "\r\n" }

    context 'when file contains \r\n line endings' do
      let(:contents) { "CR-LF\r\nline\r\nendings\r\n" }

      it { should pass }
    end

    context 'when file contains \n line endings' do
      let(:contents) { "LF\nline\nendings\n" }

      it { should fail_hook }
    end
  end

  unless Overcommit::OS.windows?
    context 'when attempting to check a binary file' do
      let(:contents) { "\xFF\xD8\xFF\xE0\u0000\u0010JFIF" }

      it { should warn }
    end
  end
end
