# frozen_string_literal: true

require 'spec_helper'
require 'overcommit/hook_context/diff'

describe Overcommit::HookContext::Diff do
  let(:config) { double('config') }
  let(:args) { [] }
  let(:input) { double('input') }
  let(:context) { described_class.new(config, args, input, diff: 'master') }

  describe '#modified_files' do
    subject { context.modified_files }

    context 'when repo contains no files' do
      around do |example|
        repo do
          `git commit --allow-empty -m "Initial commit"`
          `git checkout -b other-branch 2>&1`
          example.run
        end
      end

      it { should be_empty }
    end

    context 'when the repo contains files that are unchanged from the ref' do
      around do |example|
        repo do
          touch('some-file')
          `git add some-file`
          touch('some-other-file')
          `git add some-other-file`
          `git commit -m "Add files"`
          `git checkout -b other-branch 2>&1`
          example.run
        end
      end

      it { should be_empty }
    end

    context 'when repo contains files that have been changed from the ref' do
      around do |example|
        repo do
          touch('some-file')
          `git add some-file`
          touch('some-other-file')
          `git add some-other-file`
          `git commit -m "Add files"`
          `git checkout -b other-branch 2>&1`
          File.open('some-file', 'w') { |f| f.write("hello\n") }
          `git add some-file`
          `git commit -m "Edit file"`
          example.run
        end
      end

      it { should == %w[some-file].map { |file| File.expand_path(file) } }
    end

    context 'when repo contains submodules' do
      around do |example|
        submodule = repo do
          touch 'foo'
          `git add foo`
          `git commit -m "Initial commit"`
        end

        repo do
          `git submodule add #{submodule} test-sub 2>&1 > #{File::NULL}`
          `git commit --allow-empty -m "Initial commit"`
          `git checkout -b other-branch 2>&1`
          example.run
        end
      end

      it { should_not include File.expand_path('test-sub') }
    end
  end

  describe '#modified_lines_in_file' do
    let(:modified_file) { 'some-file' }
    subject { context.modified_lines_in_file(modified_file) }

    context 'when file contains a trailing newline' do
      around do |example|
        repo do
          touch(modified_file)
          `git add #{modified_file}`
          `git commit -m "Add file"`
          `git checkout -b other-branch 2>&1`
          File.open(modified_file, 'w') { |f| (1..3).each { |i| f.write("#{i}\n") } }
          `git add #{modified_file}`
          `git commit -m "Edit file"`
          example.run
        end
      end

      it { should == Set.new(1..3) }
    end

    context 'when file does not contain a trailing newline' do
      around do |example|
        repo do
          touch(modified_file)
          `git add #{modified_file}`
          `git commit -m "Add file"`
          `git checkout -b other-branch 2>&1`
          File.open(modified_file, 'w') do |f|
            (1..2).each { |i| f.write("#{i}\n") }
            f.write(3)
          end
          `git add #{modified_file}`
          `git commit -m "Edit file"`
          example.run
        end
      end

      it { should == Set.new(1..3) }
    end
  end

  describe '#hook_type_name' do
    subject { context.hook_type_name }

    it { should == 'pre_commit' }
  end

  describe '#hook_script_name' do
    subject { context.hook_script_name }

    it { should == 'pre-commit' }
  end

  describe '#initial_commit?' do
    subject { context.initial_commit? }

    before { Overcommit::GitRepo.stub(:initial_commit?).and_return(true) }

    it { should == true }
  end
end
