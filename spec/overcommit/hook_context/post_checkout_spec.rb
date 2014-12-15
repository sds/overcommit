require 'spec_helper'
require 'overcommit/hook_context/post_checkout'

describe Overcommit::HookContext::PostCheckout do
  let(:config) { double('config') }
  let(:args) { [previous_head, new_head, branch_flag] }
  let(:previous_head) { random_hash }
  let(:new_head) { random_hash }
  let(:branch_flag) { '1' }
  let(:context) { described_class.new(config, args) }

  describe '#previous_head' do
    subject { context.previous_head }

    it { should == previous_head }
  end

  describe '#new_head' do
    subject { context.new_head }

    it { should == new_head }
  end

  describe '#branch_checkout?' do
    subject { context.branch_checkout? }

    context 'when the flag is 0' do
      let(:branch_flag) { '0' }

      it { should == false }
    end

    context 'when the flag is 1' do
      it { should == true }
    end
  end

  describe '#file_checkout?' do
    subject { context.file_checkout? }

    context 'when the flag is 0' do
      let(:branch_flag) { '0' }

      it { should == true }
    end

    context 'when the flag is 1' do
      it { should == false }
    end
  end
end
