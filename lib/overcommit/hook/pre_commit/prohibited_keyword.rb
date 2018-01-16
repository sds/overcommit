module Overcommit::Hook::PreCommit
  class ProhibitedKeyword < Base
    def run
      errors = []

      applicable_files.each do |file|
        if File.read(file) =~ /(#{formatted_keywords})/
          errors << "#{file}: contains prohibited keyword.`"
        end
      end

      return :fail, errors.join("\n") if errors.any?

      :pass
    end

    private

    def formatted_keywords
      prohibited_keywords.map { |keyword| Regexp.quote(keyword) }.join('|')
    end

    def prohibited_keywords
      @prohibited_keywords ||= Array(config['keywords'])
    end
  end
end
