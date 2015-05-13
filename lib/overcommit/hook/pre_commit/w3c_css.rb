module Overcommit::Hook::PreCommit
  # Runs `w3c_validators` against any modified CSS files.
  #
  # @see https://github.com/alexdunae/w3c_validators
  class W3cCss < Base
    def run
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
        @validator = W3CValidators::CSSValidator.new(opts)
        @validator.set_language!(language) unless language.nil?
        @validator.set_profile!(profile) unless profile.nil?
        @validator.set_warn_level!(warn_level) unless warn_level.nil?
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

    def language
      @language ||= config['language']
    end

    # Values specified at
    #   http://www.rubydoc.info/gems/w3c_validators/1.2/W3CValidators#CSS_PROFILES
    def profile
      @profile ||= config['profile']
    end

    # One of 0, 1, 2, 'no'
    def warn_level
      @warn_level ||= config['warn_level']
    end
  end
end
