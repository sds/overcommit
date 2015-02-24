require 'spec_helper'
require 'overcommit/hook_context/post_rewrite'

describe Overcommit::HookContext::PostRewrite do
  let(:config) { double('config') }
  let(:context) { described_class.new(config, args) }

  describe '#amend?' do
    subject { context.amend? }

    context 'when rewrite was triggered by amend' do
      let(:args) { ['amend'] }

      it { should == true }
    end

    context 'when rewrite was triggered by rebase' do
      let(:args) { ['rebase'] }

      it { should == false }
    end
  end

  describe '#rebase?' do
    subject { context.rebase? }

    context 'when rewrite was triggered by amend' do
      let(:args) { ['amend'] }

      it { should == false }
    end

    context 'when rewrite was triggered by rebase' do
      let(:args) { ['rebase'] }

      it { should == true }
    end
  end
end
