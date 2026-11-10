# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Printer do
  original_methods = described_class.public_instance_methods(false).
    to_h { |name| [name, described_class.instance_method(name)] }

  let(:config) { { 'quiet' => false } }
  let(:logger) { Overcommit::Logger.silent }
  let(:context) { double('context', hook_script_name: 'pre-commit') }
  # Printer wraps methods on its class at initialization. Keep those mutations
  # local to each example, including when this spec shares a worker with CLI specs.
  let(:printer) do
    printer_class = Class.new(described_class)
    original_methods.each { |name, method| printer_class.define_method(name, method) }
    printer_class.new(config, logger, context)
  end
  let(:hook) { double('hook', name: 'Example', description: 'Check example', quiet?: false) }

  before do
    allow(logger).to receive(:partial).and_call_original
    allow(logger).to receive(:log).and_call_original
  end

  {
    nothing_to_run: [:debug, '✓ No applicable pre-commit hooks to run'],
    interrupt_triggered: [:error, "\nInterrupt signal received. Stopping hooks..."],
    run_failed: [:error, '✗ One or more pre-commit hooks failed'],
    run_warned: [:warning, '⚠ All pre-commit hooks passed, but with warnings'],
    run_succeeded: [:success, '✓ All pre-commit hooks passed'],
  }.each do |event, (level, message)|
    it "reports #{event}" do
      expect(logger).to receive(level).with(message)
      printer.public_send(event)
    end
  end

  it 'reports skipped and required hooks' do
    expect(logger).to receive(:warning).with('Skipping Example')
    expect(logger).to receive(:warning).with('Cannot skip Example since it is required')
    printer.hook_skipped(hook)
    printer.required_hook_not_skipped(hook)
  end

  it 'explains how to recover from an interrupted run' do
    expect(logger).to receive(:warning).with('⚠  Hook run interrupted by user')
    expect(logger).to receive(:warning).with(/check your stash/)
    printer.run_interrupted
  end

  it 'prints the context failure message' do
    expect(logger).to receive(:log).with('Recovery instructions')
    printer.hook_run_failed('Recovery instructions')
  end

  { pass: [:success, 'OK'], warn: [:warning, 'WARNING'],
    fail: [:error, 'FAILED'], interrupt: [:error, 'INTERRUPTED'] }.each do |status, (level, label)|
    it "reports a #{status} result and its output" do
      expect(logger).to receive(:partial).with('Check example')
      expect(logger).to receive(level).with(label)
      if status != :pass
        expect(logger).to receive(status == :warn ? :bold_warning : :bold_error).with('Details')
      end
      printer.end_hook(hook, status, 'Details')
    end
  end

  it 'reports an unknown hook status' do
    expect(logger).to receive(:error).with('???')
    expect(logger).to receive(:bold_error).with(/unknown status `:unexpected`/)
    printer.end_hook(hook, :unexpected, nil)
  end

  it 'does not print empty reports' do
    expect(logger).not_to receive(:bold_error)
    printer.end_hook(hook, :fail, '')
  end

  context 'in quiet mode' do
    let(:config) { { 'quiet' => true } }

    it 'suppresses successful run and hook output' do
      expect(logger).not_to receive(:success)
      expect(logger).not_to receive(:partial)
      printer.run_succeeded
      printer.end_hook(hook, :pass, nil)
    end

    it 'still reports failing hooks' do
      expect(logger).to receive(:partial).with('Check example')
      expect(logger).to receive(:bold_error).with('Details')
      printer.end_hook(hook, :fail, 'Details')
    end
  end
end
