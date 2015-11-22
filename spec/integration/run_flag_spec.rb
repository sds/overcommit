require 'spec_helper'

describe 'overcommit --run' do
  subject { shell(%w[overcommit --run]) }

  context 'when using an existing pre-commit hook script' do
    let(:config) do
      {
        'PreCommit' => {
          'MyHook' => {
            'enabled' => true,
            'required_executable' => './test-script',
          }
        }
      }
    end

    around do |example|
      repo do
        File.open('.overcommit.yml', 'w') { |f| f.puts(config.to_yaml) }
        echo("#!/bin/bash\nexit 0", 'test-script')
        `git add test-script`
        FileUtils.chmod(0755, 'test-script')
        example.run
      end
    end

    it 'completes successfully without blocking' do
      wait_until(timeout: 10) { subject } # Need to wait long time for JRuby startup
      subject.status.should == 0
    end
  end
end
