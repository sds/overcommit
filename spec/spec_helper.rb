require 'overcommit'

def exit(*args) ; end

# Silence output to STDOUT
class Overcommit::Logger
  def log(*args)
  end

  def partial(*args)
  end
end
