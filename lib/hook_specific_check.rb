module Causes::GitHook
  module HookRegistry
    @checks = []
    class << self
      attr_reader :checks
      def included(base)
        @checks << base
      end
    end
  end

  class HookSpecificCheck
    include FileMethods
    class << self
      attr_accessor :filetype
    end


    def name
      Causes.underscorize self.class.name.to_s.split('::').last
    end

    def skip?
      false
    end

    def staged
      @staged ||= staged_files(self.class.filetype)
    end

    def run_check
      [:bad, 'No checks defined!']
    end

  protected

    def self.file_type(type)
      self.filetype = type
    end
  end
end
