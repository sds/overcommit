# Global application constants.
module Overcommit
  OVERCOMMIT_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
  OVERCOMMIT_CONFIG_FILE_NAME = '.overcommit.yml'

  REPO_URL = 'https://github.com/brigade/overcommit'
  BUG_REPORT_URL = "#{REPO_URL}/issues"
end
