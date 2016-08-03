require 'spec_helper'

describe Overcommit::Hook::PreCommit::LineEndings do
  let(:config) do
    Overcommit::ConfigurationLoader.default_configuration.merge(
      Overcommit::Configuration.new(
        'PreCommit' => {
          'LineEndings' => {
            'representation' => representation
          }
        }
      )
    )
  end
  let(:context) { double('context') }
  subject { described_class.new(config, context) }
  let(:representation) { 'unix' }
  let(:staged_file) { 'filename.txt' }

  before do
    subject.stub(:applicable_files).and_return([staged_file])
  end

  around do |example|
    repo do
      File.open(staged_file, 'w') { |f| f.write(contents) }
      `git add #{staged_file}`
      example.run
    end
  end

  context 'when enforcing unix representation' do
    context 'when file contains windows line endings' do
      let(:contents) { "CR-LF\r\nline\r\nendings\r\n" }

      it { should fail_hook }
    end

    context 'when file contains unix line endings' do
      let(:contents) { "LF\nline\nendings\n" }

      it { should pass }
    end
  end

  context 'when enforcing windows representation' do
    let(:representation) { 'windows' }

    context 'when file contains windows line endings' do
      let(:contents) { "CR-LF\r\nline\r\nendings\r\n" }

      it { should pass }
    end

    context 'when file contains unix line endings' do
      let(:contents) { "LF\nline\nendings\n" }

      it { should fail_hook }
    end
  end
end
