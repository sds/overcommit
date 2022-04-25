# frozen_string_literal: true

require 'bundler'
require 'simplecov'
SimpleCov.start do
  add_filter 'bin/'
  add_filter 'libexec/'
  add_filter 'spec/'
  add_filter 'template-dir/'

  if ENV['CI']
    require 'simplecov-lcov'

    SimpleCov::Formatter::LcovFormatter.config do |c|
      c.report_with_single_file = true
      c.single_report_path = 'coverage/lcov.info'
    end

    formatter SimpleCov::Formatter::LcovFormatter
  end
end

require 'overcommit'
require 'tempfile'

hook_types =
  Dir[File.join(Overcommit::HOOK_DIRECTORY, '*')].
  select { |f| File.directory?(f) }.
  reject { |f| File.basename(f) == 'shared' }.
  sort

hook_types.each do |hook_type|
  require File.join(hook_type, 'base.rb')
  Dir[File.join(hook_type, '**/*.rb')].
    select { |f| File.file?(f) && File.basename(f, '.rb') != 'base' }.
    sort.
    each { |f| require f }
end

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |config|
  config.include GitSpecHelpers
  config.include OutputHelpers
  config.include ShellHelpers

  # Continue to enable the older `should` syntax for expectations
  config.expect_with :rspec do |c|
    c.syntax = [:expect, :should]
  end

  config.mock_with :rspec do |c|
    c.syntax = [:expect, :should]
  end

  config.around(:each) do |example|
    # Most tests don't deal with verification, so disable it by default
    env = {}
    unless respond_to?(:enable_verification) && enable_verification
      env['OVERCOMMIT_NO_VERIFY'] = '1'
    end

    Overcommit::Utils.with_environment env do
      example.run
    end
  end

  # Much of Overcommit depends on these helpers, so they are aggressively
  # cached. Unset them before each example so we always get fresh values.
  config.before(:each) do
    %w[git_dir repo_root].each do |var|
      Overcommit::Utils.instance_variable_set(:"@#{var}", nil)
    end
  end
end
