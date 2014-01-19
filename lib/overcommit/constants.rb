# Global application constants.
module Overcommit
  OVERCOMMIT_HOME = File.realpath(File.join(File.dirname(__FILE__), '..', '..'))

  REPO_URL = 'https://github.com/causes/overcommit'
  BUG_REPORT_URL = "#{REPO_URL}/issues"
end
