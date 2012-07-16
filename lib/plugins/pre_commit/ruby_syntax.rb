module Causes::GitHook
  class RubySyntax < HookSpecificCheck
    include HookRegistry
    file_type :rb

    def run_check
      clean = true
      output = []
      staged_files('rb').each do |staged|
        syntax = `ruby -c #{staged.path} 2>&1`
        unless $?.success?
          output += staged.filter_string(syntax).lines.to_a
          clean = false
        end
      end
      return (clean ? :good : :bad), output
    end
  end
end
