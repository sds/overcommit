
module Overcommit::Hook::PreCommit
  # Class to check yard documentation coverage.
  #
  # Use option "min_coverage_percentage" in your YardCoverage configuration
  # to set your desired documentation coverage percentage.
  #
  class YardCoverage < Base
    def run
      # Run a no-stats yard command to get the coverage
      args = flags + applicable_files
      result = execute(command, args: args)

      warnings_and_stats_text, undocumented_objects_text =
        result.stdout.split('Undocumented Objects:')

      warnings_and_stats = warnings_and_stats_text.strip.split("\n")

      # Stats are the last 7 lines before the undocumented objects
      stats = warnings_and_stats.slice(-7, 7)

      # If no stats present (shouldn't happen), warn the user and end
      if stats.class != Array || stats.length != 7
        return [:warn, 'Impossible to read the yard stats. Please, check your yard installation.']
      end

      # Check the yard coverage
      yard_coverage = check_yard_coverage(stats)
      if yard_coverage == :warn
        return [
          :warn,
          'Impossible to read yard doc coverage. Please, check your yard installation.'
        ]
      end
      return :pass if yard_coverage == :pass

      error_messages(yard_coverage, undocumented_objects_text)
    end

    private

    # Check the yard coverage
    #
    # Return a :pass if the coverage is enough, :warn if it couldn't be read,
    # otherwise, it has been read successfully.
    #
    def check_yard_coverage(stat_lines)
      if config['min_coverage_percentage']
        match = stat_lines.last.match(/^\s*([\d.]+)%\s+documented\s*$/)
        unless match
          return :warn
        end

        yard_coverage = match.captures[0].to_f
        if yard_coverage >= config['min_coverage_percentage'].to_f
          return :pass
        end

        yard_coverage
      end
    end

    # Create the error messages
    def error_messages(yard_coverage, error_text)
      first_message = "You have a #{yard_coverage}% yard documentation coverage. "\
                      "#{config['min_coverage_percentage']}% is the minimum required."

      # Add the undocumented objects text as error messages
      messages = [Overcommit::Hook::Message.new(:error, nil, nil, first_message)]

      errors = error_text.strip.split("\n")
      errors.each do |undocumented_object|
        undocumented_object_message, file_info = undocumented_object.split(/:?\s+/)
        file_info_match = file_info.match(/^\(([^:]+):(\d+)\)/)

        # In case any compacted error does not follow the format, ignore it
        if file_info_match
          file = file_info_match.captures[0]
          line = file_info_match.captures[1]
          messages << Overcommit::Hook::Message.new(
            :error, file, line, "#{file}:#{line}: #{undocumented_object_message}"
          )
        end
      end
      messages
    end
  end
end
