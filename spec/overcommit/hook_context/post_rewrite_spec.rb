require 'spec_helper'
require 'overcommit/hook_context/post_rewrite'

describe Overcommit::HookContext::PostRewrite do
  let(:config) { double('config') }
  let(:input) { double('input') }
  let(:context) { described_class.new(config, args, input) }

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

  describe '#rewritten_commits' do
    subject(:rewritten_commits) { context.rewritten_commits }

    let(:old_hash_1) { random_hash }
    let(:new_hash_1) { random_hash }
    let(:old_hash_2) { random_hash }
    let(:new_hash_2) { random_hash }

    context 'when rewrite was triggered by amend' do
      let(:args) { ['amend'] }

      before do
        input.stub(:read).and_return("#{old_hash_1} #{new_hash_1}\n")
      end

      it 'should parse rewritten commit info from the input' do
        rewritten_commits.length.should == 1
        rewritten_commits[0].old_hash.should == old_hash_1
        rewritten_commits[0].new_hash.should == new_hash_1
      end
    end

    context 'when rewrite was triggered by rebase' do
      let(:args) { ['rebase'] }

      before do
        input.stub(:read).and_return([
          "#{old_hash_1} #{new_hash_1}",
          "#{old_hash_2} #{new_hash_2}"
        ].join("\n"))
      end

      it 'should parse rewritten commit info from the input' do
        rewritten_commits.length.should == 2
        rewritten_commits[0].old_hash.should == old_hash_1
        rewritten_commits[0].new_hash.should == new_hash_1
        rewritten_commits[1].old_hash.should == old_hash_2
        rewritten_commits[1].new_hash.should == new_hash_2
      end
    end
  end
end
