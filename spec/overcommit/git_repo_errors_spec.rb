# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::GitRepo do
  it 'identifies the meaning of each submodule status prefix' do
    %w[- + U].each_with_index do |prefix, index|
      status = described_class::SubmoduleStatus.new(prefix, 'sha', 'path', nil)
      expect([status.uninitialized?, status.outdated?, status.merge_conflict?]).
        to eq([0, 1, 2].map { |value| value == index })
    end
  end

  it 'reports malformed submodule metadata' do
    allow(described_class).to receive(:`).and_return('invalid')
    allow(IniParse).to receive(:parse).and_raise(IniParse::IniParseError, 'bad metadata')
    expect { described_class.submodules }.
      to raise_error(Overcommit::Exceptions::GitSubmoduleError, /bad metadata/)
  end

  it 'ignores removed submodules on older Git versions' do
    stub_const('Overcommit::GitRepo::GIT_VERSION', Overcommit::Utils::Version.new('1.8.4'))
    metadata = "[submodule \"example\"]\npath = example\nurl = url\n"
    allow(described_class).to receive(:`).and_return(metadata)
    expect(Overcommit::Utils).to receive(:execute).with(%w[git submodule status example]).
      and_return(double('result', success?: false))
    expect(described_class.submodules).to eq([])
  end
end
