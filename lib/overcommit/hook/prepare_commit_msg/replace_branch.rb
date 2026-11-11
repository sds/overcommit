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
  #    replacement_text: '[#\1] '
  #
  # would make this hook prepend commit messages with `[#123] `.
  #
  # Similarly, a replacement text of `[\1][\2]` would result in `[123][topic]`.
  #
  # The hook does not prepend the text if the commit message already starts
  # with it, or with an autosquash prefix (`fixup! `, `squash! `, `amend! `).
  # This matters when you remove `message` or `commit` from
  # `skipped_commit_types`: `git commit -m '[#123] Fix'`, `--amend`, and
  # `--fixup` then keep one prefix.
  #
  # === Ticket IDs
  #
  # This config prepends `[PROJ-123] ` on a branch such as
  # `task/PROJ-123/fix-login`, also for `-m` and `--amend` commits:
  #
  #    PrepareCommitMsg:
  #      ReplaceBranch:
  #        enabled: true
  #        branch_pattern: '\A.*?([A-Z][A-Z0-9]+-\d+).*\z'
  #        replacement_text: '[\1] '
  #        skipped_commit_types: ['template', 'merge', 'squash']
  #        on_warn: pass # do not warn on branches without a ticket ID
  #
  # It keeps `template` skipped, because a commit template can start with a
  # `#` comment line, and the prefix would turn that line into the subject.
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
    DEFAULT_BRANCH_PATTERN = /\A(\d+)-(\w+).*\z/.freeze

    # `git rebase --autosquash` finds these commits only when the prefix starts
    # the subject.
    AUTOSQUASH_PREFIX = /\A(?:fixup|squash|amend)! /.freeze

    def run
      return :pass if skip?

      Overcommit::Utils.log.debug(
        "Checking if '#{Overcommit::GitRepo.current_branch}' matches #{branch_pattern}"
      )

      return :warn unless branch_pattern.match?(Overcommit::GitRepo.current_branch)

      modify_commit_message do |old_contents|
        if keep_message?(old_contents)
          Overcommit::Utils.log.debug("Keeping #{commit_message_filename} unchanged")
          old_contents
        else
          Overcommit::Utils.log.debug("Writing #{commit_message_filename} with #{new_template}")
          "#{new_template}#{old_contents}"
        end
      end

      :pass
    end

    def new_template
      @new_template ||=
        begin
          curr_branch = Overcommit::GitRepo.current_branch
          curr_branch.gsub(branch_pattern, replacement_text)
        end
    end

    # Compare bytes: String methods such as `lstrip` raise on a message that is
    # not valid in the default encoding, for example an amended Latin-1 commit.
    def keep_message?(contents)
      message = contents.b.lstrip
      message.match?(AUTOSQUASH_PREFIX) || starts_with_new_template?(message)
    end

    # Strip the template, because users type the prefix with or without the
    # trailing space of `replacement_text`. Without that space, a template that
    # ends in a word character, such as `PROJ-12`, must not match `PROJ-123`.
    # A blank template never matches, so a whitespace-only `replacement_text`
    # is still prepended as before.
    def starts_with_new_template?(message)
      template = new_template.b.strip
      return false if template.empty? || !message.start_with?(template)

      !(template.match?(/\w\z/) && message[template.size]&.match?(/\w/))
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
            File.read(replacement_text_config).chomp
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
      super || skipped_commit_types.include?(commit_message_source)
    end
  end
end
