require 'spec_helper'

describe Overcommit::Hook::PreCommit::NginxTest do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  let(:result) { double('result') }

  before do
    subject.stub(:applicable_files).and_return(%w[nginx.conf])
    subject.stub(:execute).and_return(result)
  end

  context 'when nginx -t exits successfully' do
    before do
      result.stub(:success?).and_return(true)
    end

    it { should pass }
  end

  context 'when nginx -t exits unsuccessfully' do
    let(:result) { double('result') }

    before do
      result.stub(success?: false, stderr: normalize_indent(<<-OUT))
        nginx: [emerg] unknown directive "erver" in nginx.conf:2
        nginx: configuration file nginx.conf test failed
      OUT
    end

    it { should fail_hook }
  end
end
