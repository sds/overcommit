# frozen_string_literal: true

require 'spec_helper'

describe 'repository state after a configuration signature error' do
  let(:enable_verification) { true }

  it 'preserves staged and unstaged changes without leaving a stash behind' do
    repo do
      echo("verify_signatures: true\nPreCommit:\n  ALL:\n    enabled: false", '.overcommit.yml')
      echo('Original staged file', 'staged.txt')
      echo('Original unstaged file', 'unstaged.txt')
      shell(%w[git add .]).status.should == 0
      shell(%w[git commit -m Initial]).status.should == 0
      install_overcommit_hooks
      shell(%w[overcommit --sign]).status.should == 0

      echo('Staged change', 'staged.txt')
      shell(%w[git add staged.txt]).status.should == 0
      echo('Unstaged change', 'unstaged.txt')
      echo('concurrency: 4', '.overcommit.yml', append: true)
      index = shell(%w[git write-tree]).stdout
      diff = shell(%w[git diff --binary]).stdout
      stashes = shell(%w[git stash list]).stdout

      result = shell(%w[git commit -m Test])

      result.status.should_not == 0
      (result.stdout + result.stderr).should include 'Signature of configuration file has changed'
      shell(%w[git write-tree]).stdout.should == index
      shell(%w[git diff --binary]).stdout.should == diff
      shell(%w[git stash list]).stdout.should == stashes
    end
  end
end
