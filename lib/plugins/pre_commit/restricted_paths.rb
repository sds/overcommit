module Causes::GitHook
  class RestrictedPaths < HookSpecificCheck
    include HookRegistry
    RESTRICTED_PATHS = %w[vendor]

    def run_check
      RESTRICTED_PATHS.each do |path|
        if !system("git diff --cached --quiet -- #{path}")
          return :stop, "changes staged under #{path}"
        end
      end
      return :good
    end
  end
end
