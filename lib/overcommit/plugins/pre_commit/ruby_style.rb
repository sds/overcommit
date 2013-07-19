module Overcommit::GitHook
  class RubyStyle < HookSpecificCheck
    include HookRegistry
    file_type :rb

    def run_check
      unless in_path?('rubocop')
        return :warn, 'rubocop not installed -- run `gem install rubocop`'
      end

      paths = staged.map { |s| s.path }.join(' ')

      output = `rubocop --format=emacs --silent #{paths} 2>&1`
      return :good if $?.success?

      return :bad, output
    end
  end
end
