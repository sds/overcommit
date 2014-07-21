module Overcommit::Hook::PreCommit
  # Checks the syntax of any modified Travis CI files with the travis-yaml gem.
  class TravisLint < Base
    def run
      return :warn, 'travis-yaml is not usable on JRuby due to its dependence Psych' if using_jruby?

      begin
        require_travis_yaml
      rescue LoadError
        return :warn, 'travis-yaml not installed -- run `gem install travis-yaml`'
      end

      return :good if success?

      [:bad, formatted_results.strip]
    end

  private

    def results
      @results ||= applicable_files.each_with_object({}) do |file, results|
        results[file] = Travis::Yaml.parse(IO.read(file)).nested_warnings
      end
    end

    def success?
      results.values.all?(&:empty?)
    end

    def formatted_results
      results.each_with_object('') do |(filename, warnings), string|
        string << "#{filename}:\n"
        warnings.each do |key, message|
          warning = key.empty? ? "  #{message}" : "  #{key.join('.')} section - #{message}\n"
          string << warning
        end
        string << "\n"
      end
    end

    def require_travis_yaml
      require 'travis/yaml'
    end

    def using_jruby?
      RUBY_PLATFORM == 'java'
    end
  end
end
