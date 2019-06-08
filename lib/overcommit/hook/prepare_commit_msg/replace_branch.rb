# frozen_string_literal: true

module Overcommit::Hook::PrepareCommitMsg
  # Prepends the commit message with a message based on the branch name.
  # It's possible to reference parts of the branch name through the captures in
  # the `branch_pattern` regex.
  class ReplaceBranch < Base
    def run
      return :pass if skipped_commit_types.include? commit_message_source

      Overcommit::Utils.log.debug(
        "Checking if '#{Overcommit::GitRepo.current_branch}' matches #{branch_pattern}"
      )

      return :warn unless branch_pattern.match?(Overcommit::GitRepo.current_branch)

      Overcommit::Utils.log.debug("Writing #{commit_message_filename} with #{new_template}")

      modify_commit_message do |old_contents|
        "#{new_template}\n#{old_contents}"
      end

      :pass
    end

    def new_template
      @new_template ||= Overcommit::GitRepo.current_branch.gsub(branch_pattern, replacement_text)
    end

    def branch_pattern
      @branch_pattern ||=
        begin
          pattern = config['branch_pattern']
          Regexp.new((pattern || '').empty? ? '\A.*\w+[-_](\d+).*\z' : pattern)
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
  end
end
