module Overcommit::Hook::PostCheckout
  # Scans source code each time HEAD changes to generate an up-to-date index of
  # all function/variable definitions, etc.
  class IndexTags < Base
    def run
      unless in_path?('ctags')
        return :good # Silently ignore
      end

      index_tags_in_background

      :good
    end

  private

    SCRIPT_LOCATION = Overcommit::Utils.script_path('index-tags')

    def index_tags_in_background
      # TODO: come up with Ruby 1.8-friendly way to do this
      Process.detach(Process.spawn(SCRIPT_LOCATION))
    end
  end
end
