require 'singleton'

# Provides a handler for interrupt signals (SIGINT), allowing the application to
# finish what it's currently working on.
class InterruptHandler
  include Singleton

  attr_accessor :isolate_signals, :signal_received

  def initialize
    self.isolate_signals = false
    self.signal_received = false

    Signal.trap('INT') do
      if isolate_signals
        self.signal_received = true
      else
        raise Interrupt
      end
    end
  end

  class << self
    def disable!
      instance.isolate_signals = false
    end

    def enable!
      instance.isolate_signals = true
    end

    def isolate_from_interrupts
      instance.signal_received = false
      instance.isolate_signals = true
      result = yield
      instance.isolate_signals = false
      result
    end

    def signal_received?
      instance.signal_received
    end
  end
end
