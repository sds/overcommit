
module Overcommit::Hook::PreCommit
  # Class to check yard documentation coverage.
  #
  # Use option "min_coverage_percentage" in your CheckYardCoverage configuration
  # to set your desired documentation coverage percentage.
  #
  class CheckYardCoverage < Base
    def run
      # Run a no-stats yard command to get the coverage
      args = %w[-n --no-save --list-undoc --compact] + flags + applicable_files
      result = execute(command, args: args)

      warnings_and_stats_text, undocumented_objects_text = result.stdout.split('Undocumented Objects:')

      warnings_and_stats = warnings_and_stats_text.strip.split("\n")

      # Stats are the last 7 lines before the undocumented objects
      stats = warnings_and_stats[-7..100]

      # If no stats present (shouldn't happen), warn the user and end
      unless stats
        return [:warn, 'Impossible to read the yard stats. Please, check your yard installation.']
      end

      # Check the yard doc coverage percentage
      yard_coverage = nil
      if config['min_coverage_percentage']
        match = stats.last.match(/^\s*([\d.]+)%\s+documented\s*$/)
        if match
          yard_coverage = match.captures[0].to_f
          if yard_coverage >= config['min_coverage_percentage'].to_f
            return :pass
          end
        else
          return [:warn, 'Impossible to read the yard documentation coverage. Please, check your yard installation.']
        end
      end

      first_message = "You have a #{yard_coverage}% yard documentation coverage. "\
                      "#{config['min_coverage_percentage']}% is the minimum required."

      # Add the undocumented objects text as error messages
      messages = [Overcommit::Hook::Message.new(:error, nil, nil, first_message)]
      undocumented_objects = undocumented_objects_text.strip.split("\n")
      undocumented_objects.each do |undocumented_object|
        undocumented_object_message, file_info = undocumented_object.split(/:?\s+/)
        file_info_match = file_info.match(/^\(([^:]+):(\d+)\)/)
        # In case any compacted error does not follow the format, ignore it
        if file_info_match
          file = file_info_match.captures[0]
          line = file_info_match.captures[1]
          messages << Overcommit::Hook::Message.new(:error, file, line, "#{file}:#{line}: #{undocumented_object_message}")
        end
      end
      messages
    end
  end
end
