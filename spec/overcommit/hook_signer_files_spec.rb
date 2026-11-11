# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::HookSigner, 'with repository commands' do
  let(:enable_verification) { true }
  let(:script_path) { File.expand_path('hook-script') }
  let(:command) { script_path }
  let(:config) do
    Overcommit::Configuration.new(
      'PreCommit' => { 'CustomScript' => { 'enabled' => true, 'command' => [command] } }
    )
  end
  let(:context) { double('context', hook_type_name: 'pre_commit', hook_class_name: 'PreCommit') }
  let(:signer) { described_class.new('CustomScript', config, context) }

  around do |example|
    repo { example.run }
  end

  before do
    File.write(script_path, 'original command')
  end

  it 'rejects untracked repository commands when signing is enabled' do
    expect { signer.update_signature! }.to raise_error(Overcommit::Exceptions::InvalidHookDefinition,
                                                       /must be tracked by Git/)
  end

  shared_examples 'a signed repository command' do
    it 'signs the actual file and requires fresh approval when its contents change' do
      Overcommit::Utils.execute(['git', 'add', script_path])
      expect(File.realpath(signer.hook_path)).to eq(File.realpath(script_path))
      signer.update_signature!
      expect(signer.signature_verified?).to eq(true)

      File.write(script_path, 'modified command')
      expect(signer.signature_verified?).to eq(false)

      File.write(script_path, 'original command')
      expect(signer.signature_verified?).to eq(true)
    end
  end

  include_examples 'a signed repository command'

  context 'with a relative command path' do
    let(:command) { ".#{Overcommit::OS.windows? ? '\\' : '/'}hook-script" }

    include_examples 'a signed repository command'
  end

  it 'recognizes a Windows-relative command path' do
    allow(Overcommit::OS).to receive(:windows?).and_return(true)
    expect(signer.signable_file?('.\\hook-script')).to eq(true)
  end
end
