require 'rake'
require './helper'

include Helper

def install_repos(options = {})
  puts
  puts "Installing Git hooks to #{repos.join(',')}"
  repos.each do |repo|
    unless git_repo?(repo_path(repo))
      error "  #{repo_path(repo)} is not a Git repository"
      next
    end
    copy_hooks(repo, options)
    copy_scripts(repo) if options[:method] == :copy
  end
  puts
end

desc 'Install git hooks to one or more repos'
task :install do
  install_repos(:method => :link)
end

desc 'Copy git hooks to one or more repos'
task :copy do
  install_repos(:method => :copy)
end

%w[copy install].each do |ns|
  namespace ns do
    desc "Install hooks to all Causes repos#{' via copying' if ns == 'copy'}"
    task :all do
      ENV['REPOS'] = all_repos.join(',')
      Rake::Task[:install].invoke
    end
  end
end
