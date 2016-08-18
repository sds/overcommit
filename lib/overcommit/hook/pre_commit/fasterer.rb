module Overcommit::Hook::PreCommit
  # Runs `fasterer` against any modified Ruby files.
  #
  # @see https://github.com/DamirSvrtan/fasterer
  class Fasterer < Base
    def run
      result = execute(command, args: applicable_files)
      output = result.stdout

      if extract_offense_num(output) == 0
        :pass
      else
        return [:warn, output]
      end
    end

    private

    def extract_offense_num(raw_output)
      raw_output.scan(/(\d+) offense detected/).flatten.map(&:to_i).inject(0, :+)
    end
  end
end
