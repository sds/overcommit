begin
  require 'rubygems'
rescue LoadError => e
  missing = e.message.split(' ').last
  puts "'#{missing}' gem not available"
end

real_hook = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__

require File.expand_path('../../staged_file', __FILE__)

SCRIPTS_PATH = File.expand_path('../../scripts/', real_hook)

module Causes
  class PreCommitHook
    include GitHook

    def check_ruby_syntax
      clean = true
      output = []
      staged_files('rb').each do |staged|
        syntax = `ruby -c #{staged.path} 2>&1`
        unless $? == 0
          output += staged.filter_string(syntax).to_a
          clean = false
        end
      end
      return (clean ? :good : :bad), output
    end

    # catches trailing whitespace, conflict markers etc
    def check_whitespace
      output = `git diff --check --cached`
      return ($?.exitstatus.zero? ? :good : :stop), output
    end

    def check_yaml_syntax
      clean = true
      output = []
      modified_files('yml').each do |file|
        staged = StagedFile.new(file)
        begin
          YAML.load_file(staged.path)
        rescue ArgumentError => e
          output << "#{e.message} parsing #{file}"
          clean = false
        end
      end
      return (clean ? :good : :bad), output
    end

  end
end
