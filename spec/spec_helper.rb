require 'overcommit'

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true
  config.formatter = :documentation
end

def exit(*args) ; end

# Silence output to STDOUT
class Overcommit::Logger
  def log(*args)
  end

  def partial(*args)
  end
end
