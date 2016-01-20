if ENV['TRAVIS']
  # When running in Travis, report coverage stats to Coveralls.
  require 'coveralls'
  Coveralls.wear!
else
  # Otherwise render coverage information in coverage/index.html and display
  # coverage percentage in the console.
  require 'simplecov'
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

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

RSpec.configure do |config|
  config.include GitSpecHelpers
  config.include OutputHelpers
  config.include ShellHelpers

  # Continue to enable the older `should` syntax for expectations
  config.expect_with :rspec do |c|
    c.syntax = [:expect, :should]
  end

  config.mock_with :rspec do |c|
    c.syntax = :should
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
