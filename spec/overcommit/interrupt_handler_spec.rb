# frozen_string_literal: true

require 'spec_helper'

describe InterruptHandler do
  let(:handler) { described_class.instance }
  let(:signal_handler) do
    callback = nil
    allow(Signal).to receive(:trap).with('INT') { |&block| callback = block }
    handler.send(:initialize)
    callback
  end

  around do |example|
    previous = [handler.isolate_signals, handler.signal_received, handler.reenable_on_interrupt]
    example.run
  ensure
    handler.isolate_signals, handler.signal_received, handler.reenable_on_interrupt = previous
  end

  it 'records an isolated interrupt without raising' do
    callback = signal_handler
    described_class.enable!
    callback.call
    expect(handler.signal_received).to eq(true)
  end

  it 'propagates unisolated interrupts' do
    callback = signal_handler
    described_class.disable!
    expect { callback.call }.to raise_error(Interrupt)
  end

  it 'restores isolation before propagating a temporary interrupt' do
    callback = signal_handler
    expect do
      described_class.disable_until_finished_or_interrupted { callback.call }
    end.to raise_error(Interrupt)
    expect(handler.isolate_signals).to eq(true)
    expect(handler.reenable_on_interrupt).to eq(false)
  end

  it 'restores isolation when the block raises another error' do
    expect do
      described_class.disable_until_finished_or_interrupted { raise 'failure' }
    end.to raise_error('failure')
    expect(handler.isolate_signals).to eq(true)
  end

  it 'clears old signals and returns the isolated block result' do
    handler.signal_received = true
    expect(described_class.isolate_from_interrupts { :result }).to eq(:result)
    expect(handler.signal_received).to eq(false)
    expect(handler.isolate_signals).to eq(false)
  end
end
