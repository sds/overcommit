require 'singleton'

# Provides a handler for interrupt signals (SIGINT), allowing the application to
# finish what it's currently working on.
class InterruptHandler
  include Singleton

  attr_accessor :isolate_signals, :signal_received, :reenable_on_interrupt

  # Initialize safe interrupt signal handling.
  def initialize
    self.isolate_signals = false
    self.signal_received = false
    self.reenable_on_interrupt = false

    Signal.trap('INT') do
      if isolate_signals
        self.signal_received = true
      else
        if reenable_on_interrupt
          self.reenable_on_interrupt = false
          self.isolate_signals = true
        end

        raise Interrupt # Allow interrupt to propagate to code
      end
    end
  end

  class << self
    # Provide a way to allow a single Ctrl-C interrupt to happen and atomically
    # re-enable interrupt protections once that interrupt is propagated.
    #
    # This prevents a race condition where code like the following:
    #
    #  begin
    #    InterruptHandler.disable!
    #    ... do stuff ...
    #  rescue Interrupt
    #    ... handle it ...
    #  ensure
    #    InterruptHandler.enable!
    #  end
    #
    # ...could have the `enable!` call to the interrupt handler not called in
    # the event another interrupt was received in between the interrupt being
    # handled and the `ensure` block being entered.
    #
    # Thus you should always write:
    #
    #  begin
    #    InterruptHandler.disable_until_finished_or_interrupted do
    #      ... do stuff ...
    #    end
    #  rescue Interrupt
    #    ... handle it ...
    #  rescue
    #    ... handle any other exceptions ...
    #  end
    def disable_until_finished_or_interrupted
      instance.reenable_on_interrupt = true
      instance.isolate_signals = false
      yield
    ensure
      instance.isolate_signals = true
    end

    # Disable interrupt isolation.
    def disable!
      instance.isolate_signals = false
    end

    # Enable interrupt isolation.
    def enable!
      instance.isolate_signals = true
    end

    # Enable interrupt isolation while executing the provided block.
    #
    # @yield block to execute with interrupt isolation
    def isolate_from_interrupts
      instance.signal_received = false
      instance.isolate_signals = true
      result = yield
      instance.isolate_signals = false
      result
    end
  end
end
