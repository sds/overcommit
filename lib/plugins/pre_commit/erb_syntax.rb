module Causes::GitHook
  class ErbSyntax
    include HookSpecificCheck
    ERB_CHECKER = 'bin/check-rails-erb'

    def skip?
      return :warn, 'Bundler is not installed' unless in_path? 'bundle'
      unless File.executable? ERB_CHECKER
        return :warn, "Can't find/execute #{ERB_CHECKER}"
      end
    end

    def run_check
      staged = staged_files('erb')
      return :good, nil if staged.empty?

      output = `bundle exec #{ERB_CHECKER} #{staged.map{ |file| file.path }.join(' ')}`
      staged.each { |s| output = s.filter_string(output) }
      return (output !~ /: compile error$/ ? :good : :bad), output
    end
  end
end
