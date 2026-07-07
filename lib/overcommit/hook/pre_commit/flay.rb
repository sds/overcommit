# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `flay` against any modified files.
  #
  # @see https://github.com/seattlerb/flay
  class Flay < Base
    # Flay prints two kinds of messages:
    #
    # 1) IDENTICAL code found in :defn (mass*2 = MASS)
    # file_path_1.rb:LINE_1
    # file_path_2.rb:LINE_2
    #
    # 2) Similar code found in :defn (mass = MASS)
    # file_path_1.rb:LINE_1
    # file_path_2.rb:LINE_2
    #

    def run
      command = ['flay', '--mass', @config['mass_threshold'].to_s, '--fuzzy', @config['fuzzy'].to_s]
      # Use a more liberal detection method
      command += ['--liberal'] if @config['liberal']
      messages = []
      # Run the command for each file
      applicable_files.each do |file|
        result = execute(command, args: [file])
        # flay exits non-zero both when it finds duplication (with output on
        # stdout) and when it crashes internally. A crash leaves stdout empty
        # and writes a backtrace to stderr, so treat that as an error instead
        # of silently passing.
        if !result.success? && result.stdout.strip.empty?
          return :fail, result.stderr
        end

        results = result.stdout.split("\n\n")
        results.shift
        unless results.empty?
          error_message = results.join("\n").gsub(/^\d+\)\s*/, '')
          message = Overcommit::Hook::Message.new(:error, nil, nil, error_message)
          messages << message
        end
      end
      messages
    end
  end
end
