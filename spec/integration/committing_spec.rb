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

    its(:status) { should_not be_zero }
  end

  context 'when no hooks fail' do
    before do
      `git config --local user.name 'John Doe'`
    end

    its(:status) { should be_zero }
  end
end
