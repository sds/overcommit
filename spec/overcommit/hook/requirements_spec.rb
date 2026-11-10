# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::Base, 'requirements' do
  let(:settings) { {} }
  let(:config) { double('config', for_hook: settings) }
  let(:hook) { described_class.new(config, double('context')) }

  it 'requires subclasses to implement run' do
    expect { hook.run }.to raise_error(NotImplementedError, /must define/)
  end

  it 'exposes whether a hook is required' do
    settings['required'] = true
    expect(hook.required?).to eq(true)
  end

  it 'delegates background commands' do
    expect(Overcommit::Utils).to receive(:execute_in_background).
      with(['example']).and_return(:process)
    expect(hook.execute_in_background(['example'])).to eq(:process)
  end

  it 'reports a missing executable without an installation hint' do
    settings['required_executable'] = 'missing'
    allow(hook).to receive(:in_path?).with('missing').and_return(false)
    status, output = hook.run_and_transform
    expect(status).to eq(:fail)
    expect(output).to end_with('execute permissions')
  end

  it 'loads available libraries before running' do
    settings['required_library'] = 'available'
    expect(hook).to receive(:require).with('available')
    allow(hook).to receive(:run).and_return(:pass)
    expect(hook.run_and_transform.first).to eq(:pass)
  end

  [nil, 'gem install example'].each do |install_command|
    it "reports missing libraries with installation hint #{install_command.inspect}" do
      settings.merge!('required_libraries' => %w[first second],
                      'install_command' => install_command)
      allow(hook).to receive(:require).and_raise(LoadError)
      expect(hook).not_to receive(:run)
      status, output = hook.run_and_transform
      expect(status).to eq(:fail)
      expect(output).to include("Unable to load 'first'", "Unable to load 'second'")
      expect(output).to include("install via #{install_command}") if install_command
    end
  end
end
