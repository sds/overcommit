# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PostMerge::ComposerInstall do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  let(:result) { double('result') }

  before do
    subject.stub(:execute).and_return(result)
  end

  context 'when composer install exits successfully' do
    before do
      result.stub(:success?).and_return(true)
    end

    it { should pass }
  end

  context 'when composer install exits unsuccessfully' do
    before do
      result.stub(success?: false, stdout: 'Composer could not find a composer.json file')
    end

    it { should fail_hook }
  end
end
