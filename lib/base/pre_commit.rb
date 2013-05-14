require 'rubygems'
require File.expand_path('../../staged_file', __FILE__)

module Causes
  class PreCommitHook
    include GitHook

    def requires_modified_files?
      true
    end
  end
end
