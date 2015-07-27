module Overcommit::Hook::PreCommit
  # Checks for images that can be optimized with `image_optim`.
  #
  # @see https://github.com/toy/image_optim
  class ImageOptim < Base
    def run
      result = execute(command, args: applicable_files)
      return [:fail, result.stdout + result.stderr] unless result.success?

      optimized_files = extract_optimized_files(result.stdout)
      return :pass if optimized_files.empty?

      output = "The following images are optimizable:\n#{optimized_files.join("\n")}"
      output += "\n\nOptimize them by running `#{command.join(' ')} #{optimized_files.join(' ')}`"
      [:fail, output]
    end

    private

    def extract_optimized_files(output)
      output.split("\n").
             select { |line| line =~ /^\d+/ }.
             map    { |line| line.split(/\s+/).last }
    end
  end
end
