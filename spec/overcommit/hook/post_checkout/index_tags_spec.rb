require 'spec_helper'

describe Overcommit::Hook::PostCheckout::IndexTags do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:in_path?).and_return(installed)
    subject.stub(:index_tags_in_background)
  end

  context 'when ctags is not installed' do
    let(:installed) { false }

    it { should pass }
  end

  context 'when ctags is installed' do
    let(:installed) { true }

    it { should pass }
  end
end
