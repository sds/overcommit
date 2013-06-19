module Overcommit::GitHook
  class XmlFormat < HookSpecificCheck
    include HookRegistry
    file_type :xml

    def run_check
      cmd = 'tidy'
      unless in_path? cmd
        return :warn, 'Run `apt-get install #{cmd}`'
      end

      output = `#{cmd} -m #{(staged.join(' '))}`.split("\n")
      return ($?.success? ? :good : :bad), output
    end
  end
end
