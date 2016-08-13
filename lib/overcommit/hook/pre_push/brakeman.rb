module Overcommit::Hook::PrePush
  # Runs `brakeman` whenever Ruby/Rails files change.
  #
  # @see http://brakemanscanner.org/
  class Brakeman < Base
    def run
      result = execute(command)
      return :pass if result.success?

      [:fail, result.stdout]
    end
  end
end
