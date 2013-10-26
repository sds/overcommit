require 'spec_helper'

describe Overcommit::GitHook::ImageOptimization::ImageSet do
  describe "#initialize(image_paths)" do
    let(:path) { '/tmp/filename.jpg20131024-7103-s1d6n9.jpg' }

    it "sets the image_paths of the image set" do
      image_set = described_class.new([path])
      expect(image_set.image_paths).to eq([path])
    end
  end

  describe "#optimize_with(ImageOptim)" do
    let(:optimized_image) { '/tmp/optimized.jpg' }
    let(:unoptimized_image) { '/tmp/unoptimized.jpg' }
    let(:image_optim) { stub('ImageOptim') }

    it "excludes already optimized images from the results" do
      image_optim.should_receive(:optimize_images!).
        with([unoptimized_image, optimized_image]).
        and_yield(unoptimized_image, true).
        and_yield(optimized_image, false).
        and_return([unoptimized_image])

      image_set = described_class.new([unoptimized_image, optimized_image])
      results = image_set.optimize_with(image_optim)
      expect(results).to eq([unoptimized_image])
    end
  end
end
