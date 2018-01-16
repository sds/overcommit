require 'spec_helper'
require 'overcommit/hook_context/pre_push'

describe Overcommit::Hook::PreCommit::ProhibitedKeyword do
  let(:hook_config) { { keywords: ['console.log(', 'eval('] } }
  let(:config) { Overcommit::ConfigurationLoader.default_configuration }
  subject { described_class.new(config, context) }

  context 'with blacklisted keyword' do
    let(:file) { create_file('console.log("hello")') }

    context 'with matching file' do
      let(:context) { double('context', modified_files: [file.path]) }

      it { should fail_hook /contains prohibited keyword./ }
    end

    context 'without matching file' do
      let(:context) { double('context', modified_files: []) }

      it { should pass }
    end
  end

  context 'without blacklisted keyword' do
    let(:file) { create_file('alert("hello")') }

    context 'with matching file' do
      let(:context) { double('context', modified_files: [file.path]) }

      it { should pass }
    end

    context 'without matching file' do
      let(:context) { double('context', modified_files: []) }

      it { should pass }
    end
  end

  private

  def create_file(content)
    Tempfile.new('index.html').tap do |file|
      file.write(content)
      file.close
    end
  end
end
