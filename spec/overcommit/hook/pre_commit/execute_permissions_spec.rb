require 'spec_helper'

describe Overcommit::Hook::PreCommit::ExecutePermissions do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }
  let(:staged_file) { 'filename.txt' }

  def make_executable_and_add(file, exec_bit)
    if Overcommit::OS.windows?
      `git update-index --add --chmod=#{exec_bit ? '+' : '-'}x #{file}`
    else
      FileUtils.chmod(exec_bit ? 0755 : 0644, file)
      `git add #{file}`
    end
  end

  before do
    subject.stub(:applicable_files).and_return([staged_file])
  end

  shared_examples_for 'a file permission hook' do
    context 'when file has execute permissions' do
      let(:exec_bit) { true }

      it { should fail_hook }
    end

    context 'when file does not have execute permissions' do
      let(:exec_bit) { false }

      it { should pass }
    end
  end

  context 'when initial commit' do
    around do |example|
      repo do
        touch staged_file
        make_executable_and_add(staged_file, exec_bit)
        example.run
      end
    end

    before do
      context.stub(:initial_commit?).and_return(true)
    end

    it_behaves_like 'a file permission hook'
  end

  context 'when not initial commit' do
    around do |example|
      repo do
        `git commit --allow-empty -m "Initial commit"`
        touch staged_file
        make_executable_and_add(staged_file, exec_bit)
        example.run
      end
    end

    before do
      context.stub(:initial_commit?).and_return(false)
    end

    it_behaves_like 'a file permission hook'
  end
end
