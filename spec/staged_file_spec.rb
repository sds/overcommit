require 'spec_helper'

describe Overcommit::StagedFile do
  let(:staged_filename) { 'staged_file.txt' }
  let(:old_file) { <<-EOF }
    Line 1
    Line 2
    Line 3
    Line 4
    Line 5
  EOF

  # Each example runs within the context of a git repository
  around do |example|
    repo do
      File.open(staged_filename, 'w') { |f| f.write(old_file.gsub(/^ +/, '')) }
      `git add #{staged_filename}`
      `git commit -m 'Initial commit'`
      File.open(staged_filename, 'w') { |f| f.write(new_file.gsub(/^ +/, '')) }
      `git add #{staged_filename}`
      example.run
    end
  end

  describe '#path' do
    let(:new_file) { 'Some file contents' }

    it 'should point to the temporary file' do
      File.basename(described_class.new(staged_filename).path).
        should_not == staged_filename
    end
  end

  describe '#contents' do
    let(:new_file) { 'Some file contents' }
    subject { described_class.new(staged_filename).contents }
    it { should == new_file }
  end

  describe '#modified_lines' do
    subject { described_class.new(staged_filename).modified_lines }

    context 'when a line was added' do
      let(:new_file) { <<-EOF }
        Line 1
        Line Added
        Line 2
        Line 3
      EOF

      it 'reports the correct line numbers' do
        subject.should include 2
      end
    end

    context 'when a line was deleted' do
      let(:new_file) { <<-EOF }
        Line 1
        Line 3
      EOF

      it 'reports no lines changed' do
        subject.should be_empty
      end
    end

    context 'when a line was modified' do
      let(:new_file) { <<-EOF }
        Line 1
        Line modified
        Line 3
      EOF

      it 'reports the line that was modified' do
        subject.should include 2
      end

      it 'ignores unmodified lines' do
        subject.should_not include 1
        subject.should_not include 3
      end
    end

    context 'when there are multiple line additions for a single hunk' do
      let(:new_file) { <<-EOF }
        Line 1
        Line 2
        Line Added
        Other Line Added
        Line 3
      EOF

      it 'reports all lines in the hunk' do
        subject.should include 3, 4
      end

      it 'ignores lines not in the hunk' do
        subject.should_not include 1
        subject.should_not include 2
        subject.should_not include 5
      end
    end

    context 'when there are multiple line modifications for a single hunk' do
      let(:new_file) { <<-EOF }
        Line 1
        Line 2 modified
        Line 3 modified
      EOF

      it 'reports all lines in the hunk' do
        subject.should include 2, 3
      end

      it 'ignores lines not in the hunk' do
        subject.should_not include 1
      end
    end

    context 'when there are multiple deletions, additions, and modifications' do
      let(:new_file) { <<-EOF }
        Line 2 modified
        Line added
        Line 4
        Line 5
        Other Line added
      EOF

      it 'reports all lines in the hunk' do
        subject.should include 1, 2, 5
      end

      it 'ignores lines not in the hunk' do
        subject.should_not include 3, 4
      end
    end
  end
end
