module Overcommit::GitHook
  class XmlFormat < HookSpecificCheck
    include HookRegistry
    file_type :xml

    def run_check
      cmd = 'xmllint'
      unless in_path? cmd
        return :warn, 'Run `apt-get install #{cmd}`'
      end

      output = staged.each {|f| `XMLLINT="    " #{cmd} --format --output #{f} #{f}`}
      return ($?.success? ? :good : :bad), output.join().split("\n")
    end
  end
end
