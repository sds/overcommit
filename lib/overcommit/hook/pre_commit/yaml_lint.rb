# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `YAMLLint` against any modified YAML files.
  #
  # @see https://github.com/adrienverge/yamllint
  class YamlLint < Base
    MESSAGE_REGEX = /
      ^(?<file>.+)
      :(?<line>\d+)
      :(?<col>\d+)
      :\s\[(?<type>\w+)\]
      \s(?<msg>.+)$
    /x

    def run
      result = execute(command, args: applicable_files)
      parse_messages(result.stdout)
    end

    private

    def parse_messages(output)
      repo_root = Overcommit::Utils.repo_root

      output.scan(MESSAGE_REGEX).map do |file, line, col, type, msg|
        line = line.to_i
        type = type.to_sym
        # Obtain the path relative to the root of the repository
        # for nicer output:
        relpath = file.dup
        relpath.slice!("#{repo_root}/")

        text = "#{relpath}:#{line}:#{col}:#{type} #{msg}"
        Overcommit::Hook::Message.new(type, file, line, text)
      end
    end
  end
end
