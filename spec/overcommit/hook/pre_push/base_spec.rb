# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PrePush::Base do
  let(:remote_name) { 'origin' }
  let(:remote_branch_deletion?) { false }
  let(:config) { double('config') }
  let(:context) { double('context') }
  let(:hook) { described_class.new(config, context) }
  describe '#run?' do
    let(:hook_config) do
      { 'skip' => skip }
    end

    before do
      allow(context).to receive(:remote_name).and_return(remote_name)
      allow(context).to receive(:remote_branch_deletion?).and_return(remote_branch_deletion?)
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

    context 'with exclude_remotes specified' do
      let(:hook_config) do
        { 'skip' => skip, 'exclude_remotes' => exclude_remotes }
      end
      let(:exclude_remotes) { nil }

      context 'skip is true and exclude_remotes is nil' do
        let(:skip) { true }
        let(:exclude_remotes) { nil }

        it { subject.should == true }
      end

      context 'skip is false and exclude_remotes is nil' do
        let(:skip) { false }
        let(:exclude_remotes) { nil }
      end

      context 'skip is true and matching exclude_remotes is nil' do
        let(:skip) { true }
        let(:exclude_remotes) { ['origin'] }

        it { subject.should == true }
      end

      context 'skip is false and matching exclude_remotes is nil' do
        let(:skip) { false }
        let(:exclude_remotes) { ['origin'] }
      end

      context 'skip is true and non-matching exclude_remotes is nil' do
        let(:skip) { true }
        let(:exclude_remotes) { ['heroku'] }

        it { subject.should == true }
      end

      context 'skip is false and non-matching exclude_remotes is nil' do
        let(:skip) { false }
        let(:exclude_remotes) { ['heroku'] }

        it { subject.should == false }
      end
    end

    context 'with ignore_branch_deletions specified' do
      let(:hook_config) do
        { 'skip' => skip, 'ignore_branch_deletions' => ignore_branch_deletions }
      end
      let(:remote_branch_deletion?) { false }
      let(:ignore_branch_deletions) { false }

      context(<<~DESC) do
        skip is true and
        remote_branch_deletion? is false and
        ignore_branch_deletions false' do
      DESC
        let(:skip) { true }
        let(:remote_branch_deletion?) { false }
        let(:ignore_branch_deletions) { nil }

        it { subject.should == true }
      end

      context(<<~DESC) do
        skip is false and
        remote_branch_deletion? is false and
        ignore_branch_deletions false' do
      DESC
        let(:skip) { false }
        let(:remote_branch_deletion?) { false }
        let(:ignore_branch_deletions) { false }

        it { subject.should == false }
      end

      context(<<~DESC) do
        skip is false and
        remote_branch_deletion? is true and
        ignore_branch_deletions false' do
      DESC
        let(:skip) { false }
        let(:remote_branch_deletion?) { true }
        let(:ignore_branch_deletions) { false }

        it { subject.should == false }
      end

      context(<<~DESC) do
        skip is false and
        remote_branch_deletion? is true and
        ignore_branch_deletions true' do
      DESC
        let(:skip) { false }
        let(:remote_branch_deletion?) { true }
        let(:ignore_branch_deletions) { true }

        it { subject.should == true }
      end

      context(<<~DESC) do
        skip is false and
        remote_branch_deletion? is false and
        ignore_branch_deletions true' do
      DESC
        let(:skip) { false }
        let(:remote_branch_deletion?) { false }
        let(:ignore_branch_deletions) { true }

        it { subject.should == false }
      end

      context(<<-DESC) do
        skip is true and
        remote_branch_deletion? is true and
        ignore_branch_deletions true' do
      DESC
        let(:skip) { true }
        let(:remote_branch_deletion?) { true }
        let(:ignore_branch_deletions) { true }

        it { subject.should == true }
      end
    end
  end
end
