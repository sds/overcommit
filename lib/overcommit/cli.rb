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

        opts.on('-a', '--all', 'Include all git hooks') do
          @options[:template] = 'all'
        end

        opts.on('-t', '--template template',
                'Specify a template of hooks') do |template|
          @options[:template] = template
        end

        opts.on('-e', '--exclude hook_name,...', Array,
                'Exclude hooks from installation') do |excludes|
          # Transform from:
          #
          #   pre_commit/test_history,commit_msg/change_id
          #
          # Into:
          #
          #   {
          #     'commit_msg' => ['change_id'],
          #     'pre_commit' => ['test_history']
          #   }
          @options[:excludes] = excludes.inject({}) do |memo, exclude|
            parts = exclude.split(%r{[:/.]})
            next memo unless parts.size == 2

            memo[parts.first] ||= []
            memo[parts.first] << parts.last

            memo
          end
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
      if @options[:targets].nil? || @options[:targets].empty?
        puts 'You must supply at least one directory to install into.'
        puts 'For example:', ''
        puts "  #{File.basename($0)} <target directory>"
        exit 2
      end

      installer = Installer.new(@options)

      @options[:targets].each do |target|
        installer.install(target)
      end

      puts 'Installation complete.'

    rescue ArgumentError => ex
      puts "Installation failed: #{ex}"
      exit 3
    end

  private

    def print_help(message, ex = nil)
      puts ex, '' if ex
      puts message
      exit 0
    end
  end
end
