# frozen_string_literal: true

# Global application constants.
module Overcommit
  HOME = File.expand_path(File.join(File.dirname(__FILE__), '..', '..')).freeze
  CONFIG_FILE_NAME = '.overcommit.yml'

  HOOK_DIRECTORY = File.join(HOME, 'lib', 'overcommit', 'hook').freeze

  REPO_URL = 'https://github.com/sds/overcommit'
  BUG_REPORT_URL = "#{REPO_URL}/issues"
end
