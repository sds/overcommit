require 'rake'
require 'helper'

include Helper


desc "Install Git hooks to one or more repos"
task :install do
  puts
  puts "Installing Git hooks to #{repos.join(',')}"
  repos.each do |repo|
    unless git_repo?(repo_path(repo))
      error "  #{repo_path(repo)} is not a Git repository"
      next
    end
    copy_hooks(repo)
    copy_scripts(repo)
  end
  puts
end

namespace :install do
  desc "Install Git hooks to all Causes repos"
  task :all do
    ENV['REPOS'] = all_repos.join(',')
    Rake::Task[:install].invoke
  end
end
