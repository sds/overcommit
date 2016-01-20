# frozen_string_literal: true

# Global application constants.
module Overcommit
  HOME = File.expand_path(File.join(File.dirname(__FILE__), '..', '..')).freeze
  CONFIG_FILE_NAME = '.overcommit.yml'.freeze

  HOOK_DIRECTORY = File.join(HOME, 'lib', 'overcommit', 'hook').freeze

  REPO_URL = 'https://github.com/brigade/overcommit'.freeze
  BUG_REPORT_URL = "#{REPO_URL}/issues".freeze
end
