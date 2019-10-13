# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PrePush::Base do
  let(:remote_name) { 'origin' }
  let(:config) { double('config') }
  let(:context) { double('context') }
  let(:hook) { described_class.new(config, context) }
  describe '#run?' do
    let(:hook_config) do
      { 'skip' => skip }
    end

    before do
      allow(context).to receive(:remote_name).and_return(remote_name)
      allow(config).to receive(:for_hook).and_return(hook_config)
    end

    subject { hook.skip? }

    context 'skip is true' do
      let(:skip) { true }

      it { subject.should == true }
    end

    context 'skip is false' do
      let(:skip) { false }

      it { subject.should == false }
    end

    context 'with exclude_remote_names specified' do
      let(:hook_config) do
        { 'skip' => skip, 'exclude_remote_names' => exclude_remote_names }
      end
      let(:exclude_remote_names) { nil }

      context 'skip is true and exclude_remote_names is nil' do
        let(:skip) { true }
        let(:exclude_remote_names) { nil }

        it { subject.should == true }
      end

      context 'skip is false and exclude_remote_names is nil' do
        let(:skip) { false }
        let(:exclude_remote_names) { nil }

        it { subject.should == false }
      end

      context 'skip is true and matching exclude_remote_names is nil' do
        let(:skip) { true }
        let(:exclude_remote_names) { ['origin'] }

        it { subject.should == true }
      end

      context 'skip is false and matching exclude_remote_names is nil' do
        let(:skip) { false }
        let(:exclude_remote_names) { ['origin'] }

        it { subject.should == true }
      end

      context 'skip is true and non-matching exclude_remote_names is nil' do
        let(:skip) { true }
        let(:exclude_remote_names) { ['heroku'] }

        it { subject.should == true }
      end

      context 'skip is false and non-matching exclude_remote_names is nil' do
        let(:skip) { false }
        let(:exclude_remote_names) { ['heroku'] }

        it { subject.should == false }
      end
    end
  end
end
