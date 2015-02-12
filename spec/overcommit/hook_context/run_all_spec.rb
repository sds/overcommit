require 'spec_helper'
require 'overcommit/hook_context/run_all'

describe Overcommit::HookContext::RunAll do
  let(:config) { double('config') }
  let(:args) { [] }
  let(:context) { described_class.new(config, args) }

  describe '#modified_files' do
    subject { context.modified_files }

    context 'when repo contains no files' do
      around do |example|
        repo do
          example.run
        end
      end

      it { should be_empty }
    end

    context 'when repo contains files' do
      around do |example|
        repo do
          FileUtils.touch('some-file')
          `git add some-file`
          FileUtils.touch('some-other-file')
          `git add some-other-file`
          `git commit -m "Add files"`
          example.run
        end
      end

      it { should == %w[some-file some-other-file].map { |file| File.expand_path(file) } }
    end

    context 'when repo contains submodules' do
      around do |example|
        submodule = repo do
          `touch foo`
          `git add foo`
          `git commit -m "Initial commit"`
        end

        repo do
          `git submodule add #{submodule} test-sub 2>&1 > /dev/null`
          example.run
        end
      end

      it { should_not include File.expand_path('test-sub') }
    end
  end

  describe '#modified_lines_in_file' do
    let(:modified_file) { 'some-file' }
    subject { context.modified_lines_in_file(modified_file) }

    context 'when repo contains files' do
      around do |example|
        repo do
          File.open(modified_file, 'w') { |f| (1..3).each { |i| f.write("#{i}\n") } }
          `git add #{modified_file}`
          `git commit -m "Add files"`
          example.run
        end
      end

      it { should == Set.new(1..4) }
    end
  end
end
