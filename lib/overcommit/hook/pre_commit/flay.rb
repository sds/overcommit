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
