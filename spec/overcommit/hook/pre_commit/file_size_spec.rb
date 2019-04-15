# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::FileSize do
  let(:config) do
    Overcommit::ConfigurationLoader.default_configuration.merge(
      Overcommit::Configuration.new(
        'PreCommit' => {
          'FileSize' => {
            'size_limit_bytes' => 10
          }
        }
      )
    )
  end

  let(:context) { double('context') }
  subject { described_class.new(config, context) }
  let(:staged_file) { 'filename.txt' }

  before do
    subject.stub(:applicable_files).and_return([staged_file])
  end

  around do |example|
    repo do
      File.open(staged_file, 'w') { |f| f.write(contents) }
      `git add "#{staged_file}" > #{File::NULL} 2>&1`
      example.run
    end
  end

  context 'when a big file is committed' do
    let(:contents) { 'longer than 10 bytes' }

    it { should fail_hook }
  end

  context 'when a small file is committed' do
    let(:contents) { 'short' }

    it { should_not fail_hook }
  end
end
