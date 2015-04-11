# Global application constants.
module Overcommit
  HOME = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
  CONFIG_FILE_NAME = '.overcommit.yml'

  HOOK_DIRECTORY = File.join(HOME, 'lib', 'overcommit', 'hook')

  REPO_URL = 'https://github.com/brigade/overcommit'
  BUG_REPORT_URL = "#{REPO_URL}/issues"
end
