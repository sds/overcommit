# frozen_string_literal: true

require 'spec_helper'

describe 'resolving cherry-pick conflicts' do
  subject { shell(%w[git commit -m "Resolve conflicts" -i some-file]) }

  let(:config) { <<-YML }
    PreCommit:
      TrailingWhitespace:
        enabled: true
  YML

  around do |example|
    repo do
      File.open('.overcommit.yml', 'w') { |f| f.write(config) }
      `git add .overcommit.yml`
      `git commit -m "Add Overcommit config"`
      echo('Master', 'some-file')
      `git add some-file`
      `git commit -m "Add some-file"`
      `git checkout -q -b branch1`
      echo('Branch 1 Addition', 'some-file')
      `git add some-file`
      `git commit -m "Add Branch 1 addition"`
      `git checkout -q master`
      `git checkout -q -b branch2`
      echo('Branch 2 Addition', 'some-file')
      `git add some-file`
      `git commit -m "Add Branch 2 addition"`
      `git checkout -q master`
      `git cherry-pick branch1 > #{File::NULL} 2>&1`
      `overcommit --install > #{File::NULL}`
      `git cherry-pick branch2 > #{File::NULL} 2>&1` # Results in cherry-pick conflict
      echo('Conflicts Resolved ', 'some-file') # Fail trailing whitespace hook
      `git add some-file`
      example.run
    end
  end

  it 'exits with a non-zero status' do
    skip 'Skipping flakey test on AppVeyor Windows builds' if ENV['APPVEYOR']
    subject.status.should_not == 0
  end

  it 'does not remove the CHERRY_PICK_HEAD file' do
    skip 'Skipping flakey test on AppVeyor Windows builds' if ENV['APPVEYOR']
    subject
    Dir['.git/*'].should include '.git/CHERRY_PICK_HEAD'
  end

  it 'keeps the commit message from the cherry-picked commit' do
    skip 'Skipping flakey test on AppVeyor Windows builds' if ENV['APPVEYOR']
    subject
    File.read(File.join('.git', 'MERGE_MSG')).should include 'Add Branch 2 addition'
  end
end
