require 'spec_helper'

describe Overcommit::Hook::PostMerge::SubmoduleStatus do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  let(:result) { double('result') }

  before do
    result.stub(:stdout).and_return("#{prefix}#{random_hash} sub (heads/master)")
    subject.stub(:execute).and_return(result)
  end

  context 'when submodule is up to date' do
    let(:prefix) { '' }

    it { should pass }
  end

  context 'when submodule is uninitialized' do
    let(:prefix) { '-' }

    it { should warn(/uninitialized/) }
  end

  context 'when submodule is outdated' do
    let(:prefix) { '+' }

    it { should warn(/out of date/) }
  end

  context 'when submodule has merge conflicts' do
    let(:prefix) { 'U' }

    it { should warn(/merge conflicts/) }
  end
end
