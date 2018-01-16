require 'spec_helper'
require 'overcommit/hook_context/pre_push'

describe Overcommit::Hook::PreCommit::ProhibitedKeyword do
  let(:hook_config) { { keywords: ['console.log(', 'eval('] } }
  let(:config) do
    Overcommit::ConfigurationLoader.default_configuration.merge(
      Overcommit::Configuration.new(
        'PreCommit' => { 'ProhibitedKeyword' => hook_config }
      )
    )
  end
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  context 'with blacklisted keyword' do
    let(:file) { create_file('console.log("hello")') }

    context 'with matching file' do
      before do
        subject.stub(:applicable_files).and_return([file.path])
      end

      it { should fail_hook /contains prohibited keyword./ }
    end

    context 'without matching file' do
      before do
        subject.stub(:applicable_files).and_return([])
      end

      it { should pass }
    end
  end

  context 'without blacklisted keyword' do
    let(:file) { create_file('alert("hello")') }
    before do
      subject.stub(:applicable_files).and_return([file.path])
    end

    context 'with matching file' do
      before do
        subject.stub(:applicable_files).and_return([file.path])
      end

      it { should pass }
    end

    context 'without matching file' do
      before do
        subject.stub(:applicable_files).and_return([])
      end

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
