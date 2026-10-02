# frozen_string_literal: true

module Overcommit::Hook::CommitMsg
  # Ensures the number of columns the subject and commit message lines occupy is
  # under the preferred limits.
  class TextWidth < Base
    # A line consisting only of a URL (optionally as a Markdown-style link
    # reference such as `[1]: https://...`) cannot be wrapped without breaking
    # the link, so it is exempt from the body width limit.
    URL_ONLY_LINE = %r{\A(\[[^\]]+\]:\s*)?[a-z][a-z0-9+.-]*://\S+\z}i.freeze

    def run
      return :pass if empty_message?

      @errors = []

      find_errors_in_subject(commit_message_lines.first.chomp)
      find_errors_in_body(commit_message_lines)

      return :warn, @errors.join("\n") if @errors.any?

      :pass
    end

    private

    def find_errors_in_subject(subject)
      max_subject_width =
        config['max_subject_width'] +
        special_prefix_length(subject)

      if subject.length > max_subject_width
        @errors << "Commit message subject must be <= #{max_subject_width} characters"
        return
      end

      min_subject_width = config['min_subject_width']
      if subject.length < min_subject_width
        @errors << "Commit message subject must be >= #{min_subject_width} characters"
        nil
      end
    end

    def find_errors_in_body(lines)
      return unless lines.count > 2

      max_body_width = config['max_body_width']

      lines[2..].each_with_index do |line, index|
        next if line.chomp.size <= max_body_width || url_only_line?(line)

        @errors << "Line #{index + 3} of commit message has > " \
                  "#{max_body_width} characters"
      end
    end

    def url_only_line?(line)
      URL_ONLY_LINE.match?(line.strip)
    end

    def special_prefix_length(subject)
      subject.match(/^(fixup|squash)! /) { |match| match[0].length } || 0
    end
  end
end
