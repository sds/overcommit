# frozen_string_literal: true

require 'spec_helper'
require 'timeout'

describe 'Hook output parsing' do
  let(:config) { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }

  {
    EsLint: ['/file.js: line 123, col 0, Warning - message', '/file.js', :warning],
    JsHint: ['C:/file.js: line 123, col 0, message (W033)', 'C:/file.js', :warning],
    HamlLint: ['C:/file.haml:123:45 [W] message', 'C:/file.haml', :warning],
    SlimLint: ['C:/file.slim:123:45 [E] message', 'C:/file.slim', :error],
    Reek: ['  C:/file.rb:123: message', 'C:/file.rb', :error],
    RubySyntax: ['file.rb:123:   syntax error,   unexpected token', 'file.rb', :error],
  }.each do |name, (output, file, type)|
    it "preserves file, line, type, and output for #{name}" do
      hook = Overcommit::Hook::PreCommit.const_get(name).new(config, context)
      allow(hook).to receive(:applicable_files).and_return([])
      stdout, stderr = name == :RubySyntax ? ['', output] : [output, '']
      allow(hook).to receive(:execute).
        and_return(Overcommit::Subprocess::Result.new(1, stdout, stderr))

      message = hook.run.fetch(0)
      expect(message.file).to eq(file)
      expect(message.line).to eq(123)
      expect(message.type).to eq(type)
      expect(message.content).to eq(output)
    end
  end

  {
    EsLint: "!9:/9#{'9' * 100_000}",
    JsHint: "9:/9#{'9' * 100_000}W",
    HamlLint: "9:9#{'0' * 100_000}",
    SlimLint: "9:9#{'0' * 100_000}",
    Reek: ' ' * 100_000,
    RubySyntax: "9:9:#{' ' * 100_000}",
  }.each do |name, output|
    it "rejects long malformed #{name} output without excessive backtracking" do
      hook = Overcommit::Hook::PreCommit.const_get(name).new(config, context)
      allow(hook).to receive(:applicable_files).and_return([])
      stdout, stderr = name == :RubySyntax ? ['', output] : [output, '']
      allow(hook).to receive(:execute).
        and_return(Overcommit::Subprocess::Result.new(1, stdout, stderr))

      Timeout.timeout(2) do
        if name == :EsLint
          expect(hook.run).to eq([:fail, ''])
        else
          expect { hook.run }.to raise_error(Overcommit::Exceptions::MessageProcessingError)
        end
      end
    end
  end
end
