require 'forwardable'

module Overcommit::Hook::PostCommit
  # Functionality common to all post-commit hooks.
  class Base < Overcommit::Hook::Base
    extend Forwardable

    def_delegators :@context, :modified_files_last_commit,
                   :modified_lines_in_file_last_commit
  end
end
