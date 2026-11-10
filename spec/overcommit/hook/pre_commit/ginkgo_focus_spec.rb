# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::GinkgoFocus do
  let(:config) { Overcommit::ConfigurationLoader.default_configuration }
  let(:hook) { described_class.new(config, double('context')) }

  before { allow(hook).to receive(:applicable_files).and_return(%w[example_test.go example.go]) }

  it 'reports focused tests as warnings at their source locations' do
    expect(hook).to receive(:execute).
      with(hook.command, args: [hook.config['keywords'].join('|'), 'example_test.go',
                                'example.go']).
      and_return(double('result', stdout: "example_test.go:7:FIt(\"example\")\n"))
    messages = hook.run
    expect(messages.size).to eq(1)
    expect(messages.first.type).to eq(:warning)
    expect(messages.first.file).to eq('example_test.go')
    expect(messages.first.line).to eq(7)
  end

  it 'selects Go test files' do
    expect(hook.applicable_test_files).to eq(['example_test.go'])
  end
end
