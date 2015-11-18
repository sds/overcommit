require 'spec_helper'
require 'yaml'

describe 'hook signing' do
  let(:enable_verification) { true }
  let(:fake_hook_config) do
    {
      'enabled' => true,
      'requires_files' => false,
      'required_executable' => script_path,
    }
  end

  let(:script_path) do
    Overcommit::OS.windows? ? '.\\pre-commit.bat' : './pre-commit'
  end

  let(:hook_script) { normalize_indent(<<-BASH) }
    echo Hello
  BASH

  let(:config) do
    {
      'verify_signatures' => verify_signatures,
      'CommitMsg' => {
        'ALL' => { 'enabled' => false },
      },
      'PreCommit' => {
        'ALL' => { 'enabled' => false },
        'FakeHook' => fake_hook_config,
      },
    }
  end

  subject { shell(%w[git commit --allow-empty -m Test]) }

  context 'when a plugin hook configuration is changed' do
    let(:new_fake_hook_config) { fake_hook_config.merge('some_option' => true) }

    let(:new_config) do
      config.dup.tap do |conf|
        conf['PreCommit']['FakeHook'] = new_fake_hook_config
      end
    end

    around do |example|
      repo do
        echo(config.to_yaml, '.overcommit.yml')
        `overcommit --install > #{File::NULL}`

        echo(hook_script, script_path)
        FileUtils.chmod(0755, script_path)
        `git add #{script_path}`

        `overcommit --sign`
        `overcommit --sign pre-commit`
        echo(new_config.to_yaml, '.overcommit.yml')

        example.run
      end
    end

    context 'and signatures are verified' do
      let(:verify_signatures) { true }

      it 'reports a signature error' do
        subject.status.should_not == 0
      end
    end

    context 'and signatures are not verified' do
      let(:verify_signatures) { false }

      it 'does not report a signature error' do
        subject.status.should == 0
      end
    end
  end

  context 'and a plugin hook is changed' do
    let(:new_hook_script) { normalize_indent(<<-BASH) }
      echo This could potentially be malicious code
    BASH

    around do |example|
      repo do
        echo(config.to_yaml, '.overcommit.yml')
        `overcommit --install > #{File::NULL}`

        echo(hook_script, script_path)
        FileUtils.chmod(0755, script_path)
        `git add #{script_path}`

        `overcommit --sign`
        `overcommit --sign pre-commit`
        echo(new_hook_script, script_path)

        example.run
      end
    end

    context 'and signatures are verified' do
      let(:verify_signatures) { true }

      it 'reports a signature error' do
        subject.status.should_not == 0
      end
    end

    context 'and signatures are not verified' do
      let(:verify_signatures) { false }

      it 'does not report a signature error' do
        subject.status.should == 0
      end
    end
  end
end
