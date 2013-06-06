require 'optparse'

module Overcommit
  class CLI
    attr_reader :options

    def initialize(arguments = [])
      @arguments = arguments
      @options   = {}
    end

    def parse_arguments
      @parser = OptionParser.new do |opts|
        opts.banner = "Usage: #{opts.program_name} [options] target"

        opts.on_tail('-h', '--help', 'Show this message') do
          print_help opts.help
        end

        opts.on_tail('-v', '--version', 'Show version') do
          log.log VERSION
          exit 0
        end

        opts.on('-l', '--list-templates', 'List built-in templates') do
          Overcommit.config.templates.each_pair do |name, configuration|
            log.bold name
            log.log YAML.dump(configuration), ''
          end
          exit 0
        end

        opts.on('-a', '--all', 'Include all git hooks') do
          @options[:template] = 'all'
        end

        opts.on('-t', '--template template',
                'Specify a template of hooks') do |template|
          @options[:template] = template
        end

        opts.on('--uninstall', 'Remove overcommit from target') do
          @options[:uninstall] = true
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
        @parser.parse!(@arguments)

        # Unconsumed arguments are our targets
        @options[:targets] = @arguments
      rescue OptionParser::InvalidOption => ex
        print_help @parser.help, ex
      end
    end

    def run
      if @options[:targets].nil? || @options[:targets].empty?
        log.warning 'You must supply at least one directory'
        log.log @parser.help
        exit 2
      end

      @options[:targets].each do |target|
        begin
          Installer.new(@options, target).run
        rescue NotAGitRepoError => e
          log.warning "Skipping #{target}: #{e}"
        end
      end

      log.success "#{@options[:uninstall] ? 'Removal' : 'Installation'} complete"

    rescue ArgumentError => ex
      error "Installation failed: #{ex}"
      exit 3
    end

  private

    def log
      Logger.instance
    end

    def print_help(message, ex = nil)
      log.error ex.to_s + "\n" if ex
      log.log message
      exit 0
    end
  end
end
