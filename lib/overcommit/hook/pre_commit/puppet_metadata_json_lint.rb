module Overcommit::Hook::PreCommit
  #
  # Run's the Puppet metadata linter. It has support for adding options
  # in the .overcommit.yaml
  #
  # @see https://voxpupuli.org/blog/2014/11/06/linting-metadata-json/
  #
  class PuppetMetadataJsonLint < Base
    MESSAGE_REGEX = /\((?<type>.*)\).*/

    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type == 'WARN' ? :warning : :error
    end

    def run
      result = execute(command, args: applicable_files)
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
