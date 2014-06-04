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
      Overcommit::Installer.new(Overcommit::Logger.silent).
                            run('.', :action => :install)
      example.run
    end
  end

  context 'when a hook fails' do
    before do
      `git config --local user.name ''`
    end

    it 'exits with a non-zero status' do
      subject.status.should_not == 0
    end
  end

  context 'when no hooks fail' do
    before do
      `git config --local user.name 'John Doe'`
    end

    it 'exits successfully' do
      subject.status.should == 0
    end
  end
end
