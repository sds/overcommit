# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PostMerge::IndexTags do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:execute_in_background)
  end

  it { should pass }
end
