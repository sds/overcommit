require 'overcommit'

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true
  config.formatter = :documentation
end

def exit(*args) ; end

Overcommit::Logger.instance.output = StringIO.new
