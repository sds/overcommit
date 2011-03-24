module Helper
  HOOKS = Dir['hooks/*'].map{|path| path.split('/').last}
  HOOKS_PATH = '.git/hooks/'


  def error(str)
    $stderr.puts "\033[31m#{str}\033[0m"
  end

  def success(str)
    puts "\033[32m#{str}\033[0m"
  end


  def all_repos
    dirs = Dir["#{source_dir}*"]
    causes_repos = []
    dirs.each do |dir|
      `cd #{dir} &&
       (git remote -v 2> /dev/null) |
         grep origin |
         grep git@github.com:causes`
      causes_repos << dir if $? == 0
    end
    causes_repos.map{|repo| repo.split('/').last}
  end

  def copy_hooks(repo)
    puts "  Installing hooks for #{repo}:"
    HOOKS.each do |hook|
      print "    #{hook} "
      FileUtils.cp hook_path(hook), target_hook_path(repo, hook)
      FileUtils.chmod 0775, target_hook_path(repo, hook)
      success "OK"
    end
  end

  def git_repo?(dir)
    File.directory?(File.join(dir, '.git'))
  end

  def hook_path(hook)
    File.expand_path(File.join('hooks', hook))
  end

  def repos
    ENV['REPOS'] ? ENV['REPOS'].split(',') : ['causes']
  end

  def repo_path(repo)
    File.join(source_dir, repo) + File::SEPARATOR
  end

  def source_dir
    File.expand_path(ENV['SOURCE_DIR'] || '~/src/') + File::SEPARATOR
  end

  def target_hook_path(repo, hook)
    File.join(repo_path(repo), HOOKS_PATH, hook)
  end
end
