module Overcommit::GitHook
  class ReleaseNote < HookSpecificCheck
    include HookRegistry

    EMPTY_RELEASE_NOTE = /^release notes?\s*[:.]?\n{2,}/im
    def run_check
      if user_commit_message.join =~ EMPTY_RELEASE_NOTE
        strip_release_note
        return :warn, 'Empty release note found, automatically removed'
      end

      :good
    end

  private

    def strip_release_note
      stripped_message = user_commit_message.join.sub(EMPTY_RELEASE_NOTE, '')

      ::File.open(commit_message_file, 'w') do |file|
        file.write(stripped_message)
      end
    end
  end
end
