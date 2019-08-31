# frozen_string_literal: true

require 'bundler'
unless ENV['OVERCOMMIT_SPEC_DISCOVERY']
  require_relative 'coverage_config'
  SimpleCov.start do
    if ENV['OVERCOMMIT_SPEC_WORKER']
      coverage_dir ENV.fetch('OVERCOMMIT_SPEC_COVERAGE_DIR')
      command_name "RSpec worker #{ENV.fetch('OVERCOMMIT_SPEC_WORKER')}"
      formatter SimpleCov::Formatter::MultiFormatter.new([]) # Only the parent formats coverage.
    end
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

  config.example_status_persistence_file_path = 'spec_example_status'
end
