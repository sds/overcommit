module Overcommit::Hook::PostCheckout
  # Scans source code each time HEAD changes to generate an up-to-date index of
  # all function/variable definitions, etc.
  class IndexTags < Base
    def run
      unless in_path?('ctags')
        return :pass # Silently ignore
      end

      index_tags_in_background

      :pass
    end

    private

    SCRIPT_LOCATION = Overcommit::Utils.script_path('index-tags')

    def index_tags_in_background
      ctags_args = config['ctags_arguments']

      # TODO: come up with Ruby 1.8-friendly way to do this
      Process.detach(Process.spawn("#{SCRIPT_LOCATION} #{ctags_args}"))
    end
  end
end
