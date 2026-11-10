# frozen_string_literal: true

require 'spec_helper'
require 'timeout'

describe Overcommit::HookRunner, 'processor reservations' do
  let(:config) { double('config', concurrency: 2) }
  let(:resource) { ConditionVariable.new }
  let(:runner) do
    condition = resource
    allow(ConditionVariable).to receive(:new).and_return(condition)
    described_class.new(config, Overcommit::Logger.silent, double('context'), double('printer'))
  end
  let(:waiting) { Queue.new }
  let(:acquired) { Queue.new }
  let(:hook) { double('hook', parallelize?: true, processors: 2) }

  [1, 2].each do |reserved|
    it "waits with #{reserved} processors occupied and resumes after they are released" do
      occupied = double('running hook', parallelize?: true, processors: reserved)
      scheduler = runner
      scheduler.send(:wait_for_slot, occupied)
      allow(resource).to receive(:wait).and_wrap_original do |method, *args|
        waiting << true
        method.call(*args)
      end

      worker = Thread.new do
        scheduler.send(:wait_for_slot, hook)
        acquired << true
      end

      Timeout.timeout(5) do
        waiting.pop
        expect(acquired).to be_empty
        scheduler.send(:release_slot, occupied)
        acquired.pop
        worker.join
      end

      # A second reservation can consume every processor after the waiter releases them.
      scheduler.send(:release_slot, hook)
      Timeout.timeout(5) { scheduler.send(:wait_for_slot, hook) }
    ensure
      worker&.kill
      worker&.join
    end
  end
end
