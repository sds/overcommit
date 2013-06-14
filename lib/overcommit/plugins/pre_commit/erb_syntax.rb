require 'erb'

module Overcommit::GitHook
  class ErbSyntax < HookSpecificCheck
    include HookRegistry
    file_type :erb
    ERB_CHECKER = 'bin/check-rails-erb'

    def skip?
      return 'Bundler is not installed' unless in_path? 'bundle'
      unless File.executable? ERB_CHECKER
        return "Can't find/execute #{ERB_CHECKER}"
      end
    end

    def run_check
      output = `bundle exec #{ERB_CHECKER} #{staged.map{ |file| file.path }.join(' ')}`
      staged.each { |s| output = s.filter_string(output) }
      return (output !~ /: compile error$/ ? :good : :bad), output
    end
  end
end
