require 'spec_helper'

describe 'specifying `gemfile` option in Overcommit configuration' do
  let(:repo_root) { File.expand_path(File.join('..', '..'), File.dirname(__FILE__)) }
  let(:fake_gem_path) { File.join('lib', 'my_fake_gem') }

  # We point the overcommit gem back to this repo since we can't assume the gem
  # has already been installed in a test environment
  let(:gemfile) { normalize_indent(<<-RUBY) }
    source 'https://rubygems.org'

    gem 'overcommit', path: '#{repo_root}'
    gem 'my_fake_gem', path: '#{fake_gem_path}'
  RUBY

  let(:gemspec) { normalize_indent(<<-RUBY) }
    Gem::Specification.new do |s|
      s.name = 'my_fake_gem'
      s.version = '1.0.0'
      s.author = 'John Doe'
      s.email = 'john.doe@example.com'
      s.summary = 'A fake gem'
      s.files = [File.join('lib', 'my_fake_gem.rb')]
    end
  RUBY

  # Specify a hook that depends on an external gem to test Gemfile loading
  let(:hook) { normalize_indent(<<-RUBY) }
    module Overcommit::Hook::PreCommit
      class FakeHook < Base
        def run
          require 'my_fake_gem'
          :pass
        end
      end
    end
  RUBY

  let(:config) { normalize_indent(<<-YAML) }
    verify_signatures: false

    CommitMsg:
      ALL:
        enabled: false

    PreCommit:
      ALL:
        enabled: false
      FakeHook:
        enabled: true
        requires_files: false
  YAML

  around do |example|
    repo do
      # Since RSpec is being run within a Bundler context we need to clear it
      # in order to not taint the test
      Bundler.with_clean_env do
        FileUtils.mkdir_p(File.join(fake_gem_path, 'lib'))
        echo(gemspec, File.join(fake_gem_path, 'my_fake_gem.gemspec'))
        touch(File.join(fake_gem_path, 'lib', 'my_fake_gem.rb'))

        echo(gemfile, '.overcommit_gems.rb')
        `bundle install --gemfile=.overcommit_gems.rb`

        echo(config, '.overcommit.yml')

        # Set BUNDLE_GEMFILE so we load Overcommit from the current repo
        ENV['BUNDLE_GEMFILE'] = '.overcommit_gems.rb'
        `bundle exec overcommit --install > #{File::NULL}`
        FileUtils.mkdir_p(File.join('.git-hooks', 'pre_commit'))
        echo(hook, File.join('.git-hooks', 'pre_commit', 'fake_hook.rb'))

        Overcommit::Utils.with_environment 'OVERCOMMIT_NO_VERIFY' => '1' do
          example.run
        end
      end
    end
  end

  subject { shell(%w[git commit --allow-empty -m Test]) }

  context 'when configuration specifies the gemfile' do
    let(:config) { "gemfile: .overcommit_gems.rb\n" + super() }

    it 'runs the hook successfully' do
      subject.status.should == 0
    end
  end

  context 'when configuration does not specify the gemfile' do
    it 'fails to run the hook' do
      subject.status.should_not == 0
    end
  end
end
