require 'spec_helper'

describe Overcommit::Hook::PostCommit::BowerInstall do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  let(:result) { double('result') }

  before do
    subject.stub(:execute).and_return(result)
  end

  context 'when bower install exits successfully' do
    before do
      result.stub(:success?).and_return(true)
    end

    it { should pass }
  end

  context 'when bower install exits unsuccessfully' do
    before do
      result.stub(success?: false, stderr: normalize_indent(<<-OUT))
        bower EMALFORMED Failed to read bower.json
      OUT
    end

    it { should fail_hook }
  end
end
