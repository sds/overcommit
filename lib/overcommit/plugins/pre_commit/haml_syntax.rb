begin
  require 'haml'
rescue LoadError => e
  puts "'haml' gem not available"
end

module Overcommit::GitHook
  class HamlSyntax < HookSpecificCheck
    include HookRegistry
    file_type :haml

    def skip?
      unless defined? Haml
        return :warn, "Can't find Haml gem"
      end
    end

    def run_check
      staged.map { |s| s.path }.each do |path|
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
