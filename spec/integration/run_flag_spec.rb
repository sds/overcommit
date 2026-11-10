# frozen_string_literal: true

require 'spec_helper'

describe 'overcommit --run' do
  subject { shell(%w[overcommit --run]) }

  context 'when enumerating tracked files' do
    around do |example|
      repo do
        echo({ 'PreCommit' => {
          'ALL' => { 'enabled' => false },
          'TrailingWhitespace' => {
            'enabled' => true, 'on_warn' => 'fail', 'include' => ['**/*.rb']
          }
        } }.to_yaml, '.overcommit.yml')
        example.run
      end
    end

    it 'succeeds for a valid empty index' do
      subject.status.should == 0
    end

    it 'fails for a tracked file with trailing whitespace' do
      echo('puts :fixture ', 'normal.rb')
      shell(%w[git add normal.rb]).status.should == 0
      subject.status.should == 65
    end

    it 'fails instead of reporting success when the index is corrupt' do
      File.binwrite('.git/index', 'invalid index')
      subject.status.should_not == 0
      (subject.stdout + subject.stderr).should include('Error listing files')
      subject.stdout.should_not include('All pre-commit hooks passed')
    end
  end

  context 'when using an existing pre-commit hook script' do
    if Overcommit::OS.windows?
      let(:script_name) { 'test-script.bat' }
      let(:script_contents) { 'exit 0' }
    else
      let(:script_name) { 'test-script' }
      let(:script_contents) { "#!/bin/bash\nexit 0" }
    end
    let(:script_path) { ".#{Overcommit::OS::SEPARATOR}#{script_name}" }

    let(:config) do
      {
        'PreCommit' => {
          'MyHook' => {
            'enabled' => true,
            'required_executable' => script_path,
          }
        }
      }
    end

    around do |example|
      repo do
        File.open('.overcommit.yml', 'w') { |f| f.puts(config.to_yaml) }
        echo(script_contents, script_path)
        `git add #{script_path}`
        FileUtils.chmod(0o755, script_path)
        example.run
      end
    end

    it 'completes successfully without blocking' do
      wait_until(timeout: 10) { subject } # Need to wait long time for JRuby startup
      subject.status.should == 0
    end
  end
end
