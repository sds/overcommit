module Overcommit::Hook::PostCheckout
  # Scans source code each time HEAD changes to generate an up-to-date index of
  # all function/variable definitions, etc.
  class IndexTags < Base
    # Location of the tag indexing script.
    SCRIPT_LOCATION = Overcommit::Utils.script_path('index-tags')

    def run
      unless in_path?('ctags')
        return :pass # Silently ignore
      end

      ctags_args = Array(config['ctags_arguments'])
      execute_in_background([SCRIPT_LOCATION] + ctags_args)

      :pass
    end
  end
end
