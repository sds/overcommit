# frozen_string_literal: true

require_relative 'pre_commit'
require_relative 'helpers/hide_unstaged_changes'
require_relative 'helpers/file_modifications'

module Overcommit::HookContext
  # Contains helpers related to contextual information used by commit-msg hooks.
  class CommitMsg < Base
    include Overcommit::HookContext::Helpers::HideUnstagedChanges
    include Overcommit::HookContext::Helpers::FileModifications

    def empty_message?
      commit_message.strip.empty?
    end

    # User commit message with Git's comment handling and no verbose diff.
    def commit_message
      commit_message_lines.join
    end

    # Updates the commit message to the specified text.
    def update_commit_message(message)
      ::File.open(commit_message_file, 'w') do |file|
        file.write(message)
      end
    end

    def commit_message_lines
      lines = raw_commit_message_lines.take_while { |line| !line.start_with?('diff --git') }
      if cleanup_mode == 'strip'
        lines.reject! { |line| line.start_with?(comment_character) }
      end
      lines
    end

    def comment_character
      @comment_character ||= Overcommit::GitConfig.comment_character
    end

    def commit_message_file
      @args[0]
    end

    def post_fail_message
      "Failed commit message:\n#{commit_message_lines.join.chomp}\n\n" \
      "Try again with your existing commit message by running:\n" \
      "git commit --edit --file=#{commit_message_file}"
    end

    private

    def cleanup_mode
      @cleanup_mode ||= Overcommit::GitConfig.commit_cleanup_mode
    end

    def raw_commit_message_lines
      ::File.readlines(commit_message_file)
    end
  end
end
