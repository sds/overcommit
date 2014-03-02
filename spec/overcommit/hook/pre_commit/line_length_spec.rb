require 'spec_helper'

describe Overcommit::Hook::PreCommit::LineLength do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }
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

  context 'when file contains lines which are too long' do
    let(:contents) { <<-CONTENTS }
      This line is purposely written so that it will be more than 89 characters and fail the check
      This line is purposely written so that it will be more than 89 characters and fail the check
    CONTENTS

    context 'when all the lines have been modified' do
      before do
        subject.stub(:modified_lines).and_return([1, 2])
      end

      it 'should fail and return the right error message' do
        expect(subject).to fail_check(
          "#{staged_file}:1: Line is too long [98/89]\n" <<
          "#{staged_file}:2: Line is too long [98/89]"
        )
      end
    end

    context 'when only the first line has been modified' do
      before do
        subject.stub(:modified_lines).and_return([1])
      end

      it 'should fail and return the right error message' do
        expect(subject).to fail_check(
          "#{staged_file}:1: Line is too long [98/89]"
        )
      end
    end

    context 'when both lines have not been modified' do
      before do
        subject.stub(:modified_lines).and_return([])
      end

      it 'should return the right warning message' do
        expect(subject).to warn(
          "Modified files have lints (on lines you didn't modify)\n" <<
          "#{staged_file}:1: Line is too long [98/89]\n" <<
          "#{staged_file}:2: Line is too long [98/89]"
        )
      end
    end
  end

  context 'when file does not contain lines which are too long' do
    let(:contents) do
      "This is fine\nThis if fine\n"
    end

    it { should pass }
  end

  context 'when custom lengths are specified' do
    let(:config) do
      super().merge(Overcommit::Configuration.new(
        'PreCommit' => {
          'LineLength' => {
            'max' => 10
          }
        }
      ))
    end

    context 'when file contains lines which are too long' do
      let(:contents) { <<-CONTENTS }
        This line is purposely written so that it will fail the check
        This line is purposely written so that it will fail the check
      CONTENTS

      context 'when all the lines have been modified' do
        before do
          subject.stub(:modified_lines).and_return([1, 2])
        end

        it 'should fail and return the right error message' do
          expect(subject).to fail_check(
            "#{staged_file}:1: Line is too long [69/10]\n" <<
            "#{staged_file}:2: Line is too long [69/10]"
          )
        end
      end
    end
  end
end
