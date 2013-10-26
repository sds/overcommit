require 'spec_helper'
require 'image_optim'

describe Overcommit::GitHook::ImageOptimization do
  describe '.filetypes' do
    it "includes only image filetypes" do
      expect(described_class.filetypes).to eq([:gif, :jpg, :png])
    end
  end

  describe "#run_check" do
    let(:image_optim) { stub(ImageOptim) }
    let(:image_set) { stub(described_class::ImageSet) }
    let(:staged_filename) { 'filename.jpg' }

    around do |example|
      repo do
        FileUtils.touch staged_filename
        `git add #{staged_filename}`
        example.run
      end
    end

    before do
      ImageOptim.should_receive(:new).and_return(image_optim)

      described_class::ImageSet.
        should_receive(:new).
        with([staged_filename]).
        and_return(image_set)
    end

    context "when a dependency of image_optim is not installed" do
      before do
        image_set.
          should_receive(:optimize_with).
          with(image_optim).
          and_raise(ImageOptim::BinNotFoundError)
      end

      it { should stop }
    end

    context "when some staged files were optimized" do
      before do
        image_set.
          should_receive(:optimize_with).
          with(image_optim).
          and_return([staged_filename])
      end

      it { should fail_check }
    end

    context "when no staged files were optimized" do
      before do
        image_set.
          should_receive(:optimize_with).
          with(image_optim).
          and_return([])
      end

      it { should pass }
    end
  end
end
