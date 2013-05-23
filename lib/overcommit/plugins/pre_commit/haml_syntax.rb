module Overcommit::GitHook
  class HamlSyntax < HookSpecificCheck
    include HookRegistry
    file_type :haml

    def run_check
      begin
        require 'haml'
      rescue LoadError
        return :warn, "'haml' gem not installed -- run `gem install haml`"
      end

      staged.each do |path|
        begin
          Haml::Engine.new(File.read(path), :check_syntax => true)
        rescue Haml::Error => e
          return :bad, e.message
        end
      end
      return :good, nil
    end
  end
end
