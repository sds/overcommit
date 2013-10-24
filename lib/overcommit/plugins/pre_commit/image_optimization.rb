require 'image_optim'

module Overcommit::GitHook
  class ImageOptimization < HookSpecificCheck
    include HookRegistry
    file_types :gif, :jpg, :png

    def run_check
      optimized_images =
        begin
          ImageSet.new(staged.map(&:original_path)).optimize!
        rescue ImageOptim::BinNotFoundError => e
          return :stop,
            "#{e.message}. The image_optim gem is dependendent on this binary. " <<
            "See https://github.com/toy/image_optim for more info."
        end

      if optimized_images.any?
        return :bad,
          "Optimized #{optimized_images.map(&:to_s).inspect}. " <<
            " Please add them to your commit."
      else
        return :good
      end
    end

    class ImageSet
      attr_reader :image_paths

      def initialize(image_paths)
        @image_paths ||= image_paths
      end

      def image_optim
        @image_optim ||= ImageOptim.new(pngout: false)
      end

      def optimize!
        results =
          image_optim.optimize_images!(image_paths) do |path, was_optimized|
            path if was_optimized
          end

        results.compact
      end
    end
  end
end
