module Overcommit::Hook::PreCommit
  # Runs `w3c_validators` against any modified HTML files.
  class W3cHtml < Base
    def run
      begin
        require 'w3c_validators'
      rescue LoadError
        return :fail, 'w3c_validators not installed -- run `gem install w3c_validators`'
      end

      collect_messages
    rescue W3CValidators::ParsingError,
           W3CValidators::ValidatorUnavailable => e
      [:fail, e.message]
    end

    private

    def collect_messages
      applicable_files.collect do |path|
        results = validator.validate_file(path)
        messages = results.errors + results.warnings
        messages.collect do |msg|
          # Some warnings are not per-line, so use 0 as a default
          line = Integer(msg.line || 0)

          # Build message by hand to reduce noise from the validator response
          text = "#{msg.type.to_s.upcase}; URI: #{path}; line #{line}: #{msg.message.strip}"
          Overcommit::Hook::Message.new(msg.type, path, line, text)
        end
      end.flatten
    end

    def validator
      unless @validator
        @validator = W3CValidators::MarkupValidator.new(opts)
        @validator.set_charset!(charset, true) unless charset.nil?
        @validator.set_doctype!(doctype, true) unless doctype.nil?
        @validator.set_debug!
      end
      @validator
    end

    def opts
      @opts ||= {
        validator_uri: config['validator_uri'],
        proxy_server:  config['proxy_server'],
        proxy_port:    config['proxy_port'],
        proxy_user:    config['proxy_user'],
        proxy_pass:    config['proxy_pass']
      }
    end

    # Values specified at
    #   http://www.rubydoc.info/gems/w3c_validators/1.2/W3CValidators#CHARSETS
    def charset
      @charset ||= config['charset']
    end

    # Values specified at
    #   http://www.rubydoc.info/gems/w3c_validators/1.2/W3CValidators#DOCTYPES
    def doctype
      @doctype ||= config['doctype']
    end
  end
end
