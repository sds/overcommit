module Overcommit::Hook::PreCommit
  # Checks for images that can be optimized with `image_optim`.
  class ImageOptim < Base
    def run
      begin
        require 'image_optim'
      rescue LoadError
        return :fail, 'image_optim not installed -- run `gem install image_optim`'
      end

      optimized_images =
        begin
          optimize_images(applicable_files)
        rescue ::ImageOptim::BinResolver::BinNotFound => e
          return :fail, "#{e.message}. The image_optim gem is dependendent on this binary."
        end

      if optimized_images.any?
        return :fail,
          "The following images are optimizable:\n#{optimized_images.join("\n")}" \
          "\n\nOptimize them by running:\n" \
          "  image_optim --skip-missing-workers #{optimized_images.join(' ')}"
      end

      :pass
    end

    private

    def optimize_images(image_paths)
      image_optim = ::ImageOptim.new(skip_missing_workers: true)

      optimized_images =
        image_optim.optimize_images(image_paths) do |path, optimized|
          path if optimized
        end

      optimized_images.compact
    end
  end
end
