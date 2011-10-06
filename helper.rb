module Helper
  DEFAULT_REPOS = ['causes']
  DEFAULT_SRC_PATH = '~/src/'
  GITHUB_ROOT = 'git@github.com:causes'
  GERRIT_REMOTE = 'gerrit.causes.com'

  HOOKS = Dir['hooks/*'].map{|path| path.split('/').last}
  SCRIPTS = 'scripts/'

  HOOKS_PATH = '.git/hooks/'


  def error(str)
    puts "\033[31m#{str}\033[0m"
  end

  def success(str)
    puts "\033[32m#{str}\033[0m"
  end


  def all_repos
    dirs = Dir["#{source_dir}*"]
    causes_repos = []
    dirs.each do |dir|
      next unless File.directory? dir
      `cd #{dir} &&
       (git remote -v 2> /dev/null) |
         grep origin |
         egrep '#{GITHUB_ROOT}|#{GERRIT_REMOTE}'`
      causes_repos << dir if $? == 0
    end
    causes_repos.map{|repo| repo.split('/').last}
  end

  def copy_hooks(repo)
    puts "  Installing hooks to #{repo}..."
    HOOKS.each do |hook|
      print "    #{hook}..."
      FileUtils.cp hook_path(hook), target_hook_path(repo, hook)
      FileUtils.chmod 0775, target_hook_path(repo, hook)
      success "OK"
    end
  end

  def copy_scripts(repo)
    print "    helper scripts..."
    FileUtils.cp_r SCRIPTS, target_script_path(repo)
    success "OK"
  end

  def git_repo?(dir)
    File.directory?(File.join(dir, '.git'))
  end

  def hook_path(hook)
    File.expand_path(File.join('hooks', hook))
  end

  def repos
    ENV['REPOS'] ? ENV['REPOS'].split(',') : DEFAULT_REPOS
  end

  def repo_path(repo)
    File.join(source_dir, repo) + File::SEPARATOR
  end

  def source_dir
    File.expand_path(ENV['SOURCE_DIR'] || DEFAULT_SRC_PATH) + File::SEPARATOR
  end

  def target_hook_path(repo, hook)
    File.join(repo_path(repo), HOOKS_PATH, hook)
  end

  def target_script_path(repo)
    File.join(repo_path(repo), HOOKS_PATH)
  end
end
