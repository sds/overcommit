module Overcommit::Hook::Shared
  # Simple template for X-Install hooks.
  module SimpleInstall
    def run
      @result = execute(command)
      return :fail, fail_output unless @result.success?
      :pass
    end

    def fail_output
      raise NotImplementedError
    end
  end
end
