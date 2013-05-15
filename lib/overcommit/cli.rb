require 'optparse'

module Overcommit
  class CLI

    def initialize(arguments = [])
      @arguments = arguments
      @options   = {}
    end

    def parse_arguments
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: #{opts.program_name} [options] target"

        opts.on_tail('-h', '--help', 'Show this message') do
          print_help opts.help
        end

        opts.on_tail('-v', '--version', 'Show version') do
          puts VERSION
          exit 0
        end
      end

      begin
        parser.parse!(@arguments)

        # Unconsumed arguments are our targets
        @options[:targets] = @arguments
      rescue OptionParser::InvalidOption => ex
        print_help parser.help, ex
      end
    end

    def run
      raise NotImplementedError, 'Nothing to see here yet'
    end

  private

    def print_help(message, ex = nil)
      puts ex, '' if ex
      puts message
      exit 0
    end
  end
end
