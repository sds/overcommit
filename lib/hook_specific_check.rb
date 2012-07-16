module Causes::GitHook
  module HookSpecificCheck
    include FileMethods
    @checks = []

    class << self
      attr_reader :checks
      def included(base)
        @checks << base
      end
    end

    def name
      self.class.name.to_s.split('::').last
    end

    def skip?
      false
    end
  end
end
