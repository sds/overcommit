# frozen_string_literal: true

require 'spec_helper'

describe 'commiting' do
  subject { shell(%w[git commit --allow-empty -m Test]) }

  let(:config) { <<-YML }
    CommitMsg:
      ALL:
        enabled: false
    PreCommit:
      ALL:
        enabled: false
      AuthorName:
        enabled: true
  YML

  around do |example|
    repo do
      File.open('.overcommit.yml', 'w') { |f| f.write(config) }
      `overcommit --install > #{File::NULL}`
      example.run
    end
  end

  context 'when a hook fails' do
    before do
      `git config --local user.name ""`
    end

    it 'exits with a non-zero status' do
      subject.status.should_not == 0
    end
  end

  context 'when no hooks fail on single author name' do
    before do
      `git config --local user.name "John"`
    end

    it 'exits successfully' do
      subject.status.should == 0
    end
  end

  context 'when no hooks fail' do
    before do
      `git config --local user.name "John Doe"`
    end

    it 'exits successfully' do
      subject.status.should == 0
    end
  end
end

describe 'commiting to an empty repo' do
  subject { shell(%w[git commit -m Test]) }

  let(:config) { <<-YML }
    CommitMsg:
      ALL:
        enabled: false
    PreCommit:
      ALL:
        enabled: false
      HardTabs:
        enabled: true
  YML

  around do |example|
    repo do
      `overcommit --install > #{File::NULL}`
      File.open('.overcommit.yml', 'w') { |f| f.write(config) }
      File.open('test.txt', 'w') { |f| f.write(file_contents) }
      `git add test.txt`
      example.run
    end
  end

  context 'when a hook fails' do
    let(:file_contents) { "\t\tFile with some hard tabs" }

    it 'exits with a non-zero status' do
      subject.status.should_not == 0
    end

    it 'does not complain about missing HEAD' do
      subject.stderr.should_not include 'HEAD'
    end

    it 'does not lose changes' do
      File.open('test.txt').read.should == file_contents
    end
  end

  context 'when no hooks fail' do
    let(:file_contents) { 'File without hard tabs' }

    it 'exits successfully' do
      subject.status.should == 0
    end

    it 'does not complain about missing HEAD' do
      subject.stderr.should_not include 'HEAD'
    end

    it 'does not lose changes' do
      subject
      File.open('test.txt').read.should == file_contents
    end
  end
end
