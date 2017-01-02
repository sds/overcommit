require 'spec_helper'

describe Overcommit::Hook::PostCommit::Commitplease do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  let(:result) { double('result') }

  before do
    subject.stub(:execute).and_return(result)
  end

  context 'when commitplease exits successfully' do
    before do
      result.stub(:success?).and_return(true)
      result.stub(:stderr).and_return('')
    end

    it { should pass }
  end

  context 'when commitplease exits unsuccessfully' do
    before do
      result.stub(success?: false, stderr: normalize_indent(<<-OUT))
        - First line must be <type>(<scope>): <subject>
        Need an opening parenthesis: (
      OUT
    end

    it { should fail_hook }
  end
end
