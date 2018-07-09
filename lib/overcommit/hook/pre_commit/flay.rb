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
      # Run the command
      result = execute(command, args: applicable_files)
      results = result.stdout.split("\n\n")
      total_score_title = results.shift
      # Check if the issues surpasses the total score threshold
      if @config['total_score_threshold']
        _, total_score = total_score_title.split(/\s*=\s*/)
        :pass if @config['total_score_threshold'].to_f >= total_score.to_f
      end
      # Format the error messages
      results.
        map(&:strip).
        reject(&:empty?).
        map { |error| message(error) }
    end

    private

    def message(error)
      Overcommit::Hook::Message.new(:error, nil, nil, error)
    end
  end
end
