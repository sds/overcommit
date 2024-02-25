# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# Development dependencies are listed below

gem 'rspec', '~> 3.0'

gem 'simplecov', '~> 0.21.0'
gem 'simplecov-lcov', '~> 0.8.0'

# Pin RuboCop for CI builds
if RUBY_VERSION < '2.7.0'
  gem 'rubocop', '1.50.0'
else
  gem 'rubocop', '1.59.0'
end

gem 'ffi' if Gem.win_platform?
