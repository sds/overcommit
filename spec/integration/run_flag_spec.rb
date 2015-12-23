require 'spec_helper'

describe 'overcommit --run' do
  subject { shell(%w[overcommit --run]) }

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
        FileUtils.chmod(0755, script_path)
        example.run
      end
    end

    it 'completes successfully without blocking' do
      wait_until(timeout: 10) { subject } # Need to wait long time for JRuby startup
      subject.status.should == 0
    end
  end
end
