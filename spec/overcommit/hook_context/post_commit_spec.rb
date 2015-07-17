require 'spec_helper'
require 'overcommit/hook_context/post_commit'

describe Overcommit::HookContext::PostCommit do
  let(:config) { double('config') }
  let(:args) { [] }
  let(:input) { double('input') }
  let(:context) { described_class.new(config, args, input) }

  describe '#modified_files' do
    subject { context.modified_files }

    it 'does not include submodules' do
      submodule = repo do
        touch 'foo'
        `git add foo`
        `git commit -m "Initial commit"`
      end

      repo do
        `git submodule add #{submodule} test-sub 2>&1 > #{File::NULL}`
        `git commit -m "Initial commit"`
        expect(subject).to_not include File.expand_path('test-sub')
      end
    end

    context 'when no files were staged' do
      around do |example|
        repo do
          `git commit --allow-empty -m "Initial commit"`
          example.run
        end
      end

      it { should be_empty }
    end

    context 'when files were added' do
      around do |example|
        repo do
          touch('some-file')
          `git add some-file`
          `git commit -m "Initial commit"`
          example.run
        end
      end

      it { should == [File.expand_path('some-file')] }
    end

    context 'when files were modified' do
      around do |example|
        repo do
          touch('some-file')
          `git add some-file`
          `git commit -m "Initial commit"`
          echo('Hello', 'some-file')
          `git add some-file`
          `git commit -m "Modify some-file"`
          example.run
        end
      end

      it { should == [File.expand_path('some-file')] }
    end

    context 'when files were deleted' do
      around do |example|
        repo do
          touch('some-file')
          `git add some-file`
          `git commit -m "Initial commit"`
          `git rm some-file`
          `git commit -m "Delete some-file"`
          example.run
        end
      end

      it { should be_empty }
    end
  end

  describe '#modified_lines_in_file' do
    let(:modified_file) { 'some-file' }
    subject { context.modified_lines_in_file(modified_file) }

    context 'when file contains a trailing newline' do
      around do |example|
        repo do
          File.open(modified_file, 'w') { |f| (1..3).each { |i| f.write("#{i}\n") } }
          `git add #{modified_file}`
          `git commit -m "Add files"`
          example.run
        end
      end

      it { should == Set.new(1..3) }
    end

    context 'when file does not contain a trailing newline' do
      around do |example|
        repo do
          File.open(modified_file, 'w') do |f|
            (1..2).each { |i| f.write("#{i}\n") }
            f.write(3)
          end

          `git add #{modified_file}`
          `git commit -m "Add files"`
          example.run
        end
      end

      it { should == Set.new(1..3) }
    end
  end

  describe '#initial_commit?' do
    subject { context.initial_commit? }

    context 'when a previous commit exists' do
      around do |example|
        repo do
          `git commit --allow-empty -m "Initial commit"`
          `git commit --allow-empty -m "Another commit"`
          example.run
        end
      end

      it { should == false }
    end

    context 'when no previous commit exists' do
      around do |example|
        repo do
          `git commit --allow-empty -m "Initial commit"`
          example.run
        end
      end

      it { should == true }
    end
  end
end
