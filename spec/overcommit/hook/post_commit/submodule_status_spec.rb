# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PostCommit::SubmoduleStatus do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  let(:submodule_status) { double('submodule_status') }

  before do
    submodule_status.stub(:path).and_return('sub')
    subject.stub(:submodule_statuses).and_return([submodule_status])
  end

  context 'when submodule is up to date' do
    before do
      submodule_status.stub(uninitialized?: false,
                            outdated?: false,
                            merge_conflict?: false)
    end

    it { should pass }
  end

  context 'when submodule is uninitialized' do
    before do
      submodule_status.stub(uninitialized?: true,
                            outdated?: false,
                            merge_conflict?: false)
    end

    it { should warn(/uninitialized/) }
  end

  context 'when submodule is outdated' do
    before do
      submodule_status.stub(uninitialized?: false,
                            outdated?: true,
                            merge_conflict?: false)
    end

    it { should warn(/out of date/) }
  end

  context 'when submodule has merge conflicts' do
    before do
      submodule_status.stub(uninitialized?: false,
                            outdated?: false,
                            merge_conflict?: true)
    end

    it { should warn(/merge conflicts/) }
  end
end
