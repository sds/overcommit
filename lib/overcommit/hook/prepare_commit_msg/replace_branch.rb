# frozen_string_literal: true

module Overcommit::Hook::PrepareCommitMsg
  # Prepends the commit message with a message based on the branch name.
  #
  # === What to prepend
  #
  # It's possible to reference parts of the branch name through the captures in
  # the `branch_pattern` regex.
  #
  # For instance, if your current branch is `123-topic` then this config
  #
  #    branch_pattern: '(\d+)-(\w+)'
  #    replacement_text: '[#\1]'
  #
  # would make this hook prepend commit messages with `[#123]`.
  #
  # Similarly, a replacement text of `[\1][\2]` would result in `[123][topic]`.
  #
  # == When to run this hook
  #
  # You can configure this to run only for specific types of commits by setting
  # the `skipped_commit_types`. The allowed types are
  #
  # - 'message'  - if message is given via `-m`, `-F`
  # - 'template' - if `-t` is given or `commit.template` is set
  # - 'commit'   - if `-c`, `-C`, or `--amend` is given
  # - 'merge'    - if merging
  # - 'squash'   - if squashing
  #
  class ReplaceBranch < Base
    DEFAULT_BRANCH_PATTERN = /\A(\d+)-(\w+).*\z/

    def run
      return :pass if skip?

      Overcommit::Utils.log.debug(
        "Checking if '#{Overcommit::GitRepo.current_branch}' matches #{branch_pattern}"
      )

      return :warn unless branch_pattern.match?(Overcommit::GitRepo.current_branch)

      Overcommit::Utils.log.debug("Writing #{commit_message_filename} with #{new_template}")

      modify_commit_message do |old_contents|
        "#{new_template}#{old_contents}"
      end

      :pass
    end

    def new_template
      @new_template ||=
        begin
          curr_branch = Overcommit::GitRepo.current_branch
          curr_branch.gsub(branch_pattern, replacement_text).strip
        end
    end

    def branch_pattern
      @branch_pattern ||=
        begin
          pattern = config['branch_pattern']
          Regexp.new((pattern || '').empty? ? DEFAULT_BRANCH_PATTERN : pattern)
        end
    end

    def replacement_text
      @replacement_text ||=
        begin
          if File.exist?(replacement_text_config)
            File.read(replacement_text_config)
          else
            replacement_text_config
          end
        end
    end

    def replacement_text_config
      @replacement_text_config ||= config['replacement_text']
    end

    def skipped_commit_types
      @skipped_commit_types ||= config['skipped_commit_types'].map(&:to_sym)
    end

    def skip?
      skipped_commit_types.include?(commit_message_source)
    end
  end
end
