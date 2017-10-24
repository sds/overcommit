module Overcommit::Hook::PreCommit
  #
  # Run's the Puppet metadata linter. It has support for adding options
  # in the .overcommit.yaml
  #
  # PreCommit:
  #   MetadataJsonLint:
  #     enabled: true
  #     strict_license: false
  #     strict_dependencies: false
  #     fail_on_warning: true
  #     description: 'Checking module metadata'
  #
  # @see https://voxpupuli.org/blog/2014/11/06/linting-metadata-json/
  #
  class MetadataJsonLint < Base
    MESSAGE_REGEX = /\((?<type>.*)\).*/

    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type == 'WARN' ? :warning : :error
    end

    def options
      [:strict_license, :strict_dependencies, :fail_on_warning].collect do |option|
        name = option.to_s.tr('_', '-')
        value = config.fetch(option.to_s) { true }
        if value
          "--#{name}"
        else
          "--no-#{name}"
        end
      end
    end

    def run
      # When metadata.json, not modified return pass
      return :pass unless applicable_files.include?('metadata.json')

      arguments = options << 'metadata.json'
      result = execute(command, args: arguments)
      output = result.stdout.chomp.gsub(/^"|"$/, '')
      return :pass if result.success? && output.empty?
      extract_messages(
        output.split("\n"),
        MESSAGE_REGEX,
        MESSAGE_TYPE_CATEGORIZER
      )
    end
  end
end
