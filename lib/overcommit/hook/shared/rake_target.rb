module Overcommit::Hook::Shared
  # runs specified rake targets. It fails on the first non-
  # successfull exit.
  #
  module RakeTarget
    def run
      targets = config['targets']

      if Array(targets).empty?
        raise 'RakeTarget: targets parameter is empty. Add at least one task to ' \
          'the targets parameter. Valid: Array of target names or String of ' \
          'target names'
      end

      targets.each do |task|
        result = execute(command + [task])
        unless result.success?
          return :fail, "Rake target #{task}:\n#{result.stdout}"
        end
      end
      :pass
    end
  end
end
