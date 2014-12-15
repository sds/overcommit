require 'spec_helper'

describe 'resolving merge conflicts' do
  subject { shell(%w[git commit -m "Resolve conflicts" -i some-file]) }

  let(:config) { <<-YML }
    PostCheckout:
      ALL:
        enabled: false
  YML

  around do |example|
    repo do
      File.open('.overcommit.yml', 'w') { |f| f.write(config) }
      `git add .overcommit.yml`
      `git commit -m "Add Overcommit config"`
      `echo "Master" > some-file`
      `git add some-file`
      `git commit -m "Add some-file"`
      `git checkout -q -b branch1`
      `echo "Branch 1 Addition" > some-file`
      `git add some-file`
      `git commit -m "Add Branch 1 addition"`
      `git checkout -q master`
      `git checkout -q -b branch2`
      `echo "Branch 2 Addition" > some-file`
      `git add some-file`
      `git commit -m "Add Branch 2 addition"`
      `git checkout -q master`
      `git merge branch1`
      `git merge branch2` # Results in merge conflict
      Overcommit::Installer.new(Overcommit::Logger.silent).
                            run('.', action: :install)
      `echo "Conflicts Resolved" > some-file`
      `git add some-file`
      example.run
    end
  end

  it 'exits successfully' do
    subject.status.should == 0
  end

  it 'does not display an error about MERGE_HEAD missing' do
    subject.stderr.should_not include 'MERGE_HEAD'
  end
end
