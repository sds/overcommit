require 'rubygems'

real_hook = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__

require File.expand_path('../../staged_file', __FILE__)

module Causes
  class PreCommitHook
    include GitHook
  end
end
