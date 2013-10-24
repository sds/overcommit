require 'spec_helper'

describe Overcommit::GitHook::ImageOptimization do
  describe '.filetypes' do
    it "includes only image filetypes" do
      expect(described_class.filetypes).to eq([:gif, :jpg, :png])
    end
  end

  describe "#run_check" do
    let(:staged_filename) { 'filename.jpg' }

    around do |example|
      repo do
        FileUtils.touch staged_filename
        `git add #{staged_filename}`
        example.run
      end
    end

    context "when a dependency of image_optim is not installed" do
      let(:image_set) { stub(described_class::ImageSet) }

      before do
        described_class::ImageSet
          .should_receive(:new)
          .with([staged_filename])
          .and_return(image_set)

        image_set.should_receive(:optimize!).and_raise(ImageOptim::BinNotFoundError)
      end

      it { should stop }
    end

    context "when some staged files were optimized" do
      let(:image_set) { stub(described_class::ImageSet) }

      before do
        described_class::ImageSet
          .should_receive(:new)
          .with([staged_filename])
          .and_return(image_set)

        image_set.should_receive(:optimize!).and_return([staged_filename])
      end

      it { should fail_check }
    end

    context "when no staged files were optimized" do
      let(:image_set) { stub(described_class::ImageSet) }

      before do
        described_class::ImageSet
          .should_receive(:new)
          .with([staged_filename])
          .and_return(image_set)

        image_set.should_receive(:optimize!).and_return([])
      end

      it { should pass }
    end
  end
end
