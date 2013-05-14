require 'rubygems'
require File.expand_path('../../staged_file', __FILE__)

module Causes
  class PreCommitHook < GitHook::BaseHook
    def requires_modified_files?
      true
    end
  end

  GitHook.register_hook(PreCommitHook)
end
