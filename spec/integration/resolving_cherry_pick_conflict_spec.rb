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
      `git cherry-pick branch1`
      Overcommit::Installer.new(Overcommit::Logger.silent).
                            run('.', :action => :install)
      `git cherry-pick branch2` # Results in cherry-pick conflict
      `echo "Conflicts Resolved " > some-file` # Fail trailing whitespace hook
      `git add some-file`
      example.run
    end
  end

  its(:status) { should == 1 }

  it 'does not remove the CHERRY_PICK_HEAD file' do
    subject
    `ls -al .git`.should include 'CHERRY_PICK_HEAD'
  end
end
