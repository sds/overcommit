# Returns the version of the available git binary.
#
# This is intended to be used to conveniently execute code based on a specific
# git version. Simply compare to a version string:
#
# @example
#   if GIT_VERSION <= '1.8.5'
#     ...
#   end
module Overcommit
  GIT_VERSION = begin
    version = `git --version`.chomp[/\d+(\.\d+)+/, 0]
    Overcommit::Utils::Version.new(version)
  end
end
