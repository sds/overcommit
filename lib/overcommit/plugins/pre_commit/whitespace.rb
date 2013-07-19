module Overcommit::GitHook
  class Whitespace < HookSpecificCheck
    include HookRegistry

    def run_check
      paths = staged.map { |s| s.path }.join(' ')

      # Catches hard tabs
      output = `grep -Inl "\t" #{paths}`
      unless output.empty?
        return :stop, "Don't use hard tabs:\n#{output}"
      end

      # Catches trailing whitespace, conflict markers etc
      output = `git diff --check --cached`
      return :stop, output unless $?.exitstatus.zero?

      :good
    end
  end
end
