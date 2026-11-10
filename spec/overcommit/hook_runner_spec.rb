# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::HookRunner do
  let(:config) { double('config', concurrency: 2, :[] => nil) }
  let(:logger) { Overcommit::Logger.silent }
  let(:context) do
    double('context', hook_type_name: 'pre_commit', setup_environment: nil,
                      cleanup_environment: nil, post_fail_message: 'Recovery instructions')
  end
  let(:printer) { double('printer').as_null_object }
  let(:runner) { described_class.new(config, logger, context, printer) }
  let(:hook) do
    double('hook', enabled?: true, skip?: false, required?: false, run?: true,
                   parallelize?: true, processors: 1, run_and_transform: [:pass, nil])
  end

  before do
    allow(Overcommit::HookLoader::BuiltInHookLoader).to receive(:new).
      and_return(double('loader', load_hooks: [hook]))
    allow(Overcommit::HookLoader::PluginHookLoader).to receive(:new).
      and_return(double('loader', load_hooks: []))
  end

  { pass: :run_succeeded, warn: :run_warned, fail: :run_failed }.each do |status, event|
    it "reports #{status} and cleans up the environment" do
      allow(hook).to receive(:run_and_transform).and_return([status, 'Details'])
      expect(printer).to receive(:end_hook).with(hook, status, 'Details')
      expect(printer).to receive(event)
      expect(context).to receive(:cleanup_environment)
      expect(printer).to receive(:hook_run_failed).with('Recovery instructions') if status == :fail
      expect(runner.run).to eq(status != :fail)
    end
  end

  [Overcommit::Exceptions::MessageProcessingError, RuntimeError].each do |error|
    it "reports #{error} as a failed hook" do
      allow(hook).to receive(:run_and_transform).and_raise(error, 'Bad output')
      expect(printer).to receive(:end_hook).with(hook, :fail, /Bad output/)
      expect(runner.run).to eq(false)
    end
  end

  it 'reports an interrupted worker and restores the environment' do
    allow(hook).to receive(:run_and_transform).and_raise(Interrupt)
    expect(printer).to receive(:run_interrupted)
    expect(context).to receive(:cleanup_environment)
    expect(runner.run).to eq(false)
  end

  it 'reports an interrupt while waiting for workers' do
    worker = double('worker', raise: nil)
    allow(Thread).to receive(:new).and_return(worker)
    allow(InterruptHandler).to receive(:disable_until_finished_or_interrupted).and_raise(Interrupt)
    expect(printer).to receive(:interrupt_triggered)
    expect(printer).to receive(:run_interrupted)
    expect(runner.run).to eq(false)
  end

  it 'reports explicitly skipped applicable hooks' do
    allow(hook).to receive(:skip?).and_return(true)
    expect(hook).not_to receive(:run_and_transform)
    expect(printer).to receive(:hook_skipped).with(hook)
    expect(runner.run).to eq(true)
  end

  it 'runs required hooks even when requested to skip them' do
    allow(hook).to receive_messages(skip?: true, required?: true, parallelize?: false)
    expect(printer).to receive(:required_hook_not_skipped).with(hook)
    expect(hook).to receive(:run_and_transform).and_return([:pass, nil])
    expect(runner.run).to eq(true)
  end

  it 'succeeds when no hooks are enabled' do
    allow(hook).to receive(:enabled?).and_return(false)
    expect(printer).to receive(:nothing_to_run)
    expect(runner.run).to eq(true)
  end

  [nil, 'Gemfile.hooks'].each do |gemfile|
    it "explains load errors with gemfile #{gemfile.inspect}" do
      allow(config).to receive(:[]).with('gemfile').and_return(gemfile)
      allow(Overcommit::HookLoader::BuiltInHookLoader).to receive(:new).and_raise(LoadError,
                                                                                  'missing')
      expect(context).not_to receive(:setup_environment)
      expect do
        runner.run
      end.to raise_error(Overcommit::Exceptions::HookLoadError, /forget.*gem.*missing/m)
    end
  end
end
