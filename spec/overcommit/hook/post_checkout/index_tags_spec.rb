require 'spec_helper'

describe Overcommit::Hook::PostCheckout::IndexTags do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:execute_in_background)
  end

  it { should pass }
end
