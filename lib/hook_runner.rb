#!/usr/bin/env ruby

unless File.symlink?(__FILE__)
  STDERR.puts "This file is not meant to be called directly."
  exit 2
end

%W[causes_hook git_hook].each do |dep|
  require File.expand_path("../#{dep}", File.realpath(__FILE__))
end

Causes.load_hooks
Causes::GitHook.run_hooks
