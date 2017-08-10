require 'fileutils'

module Overcommit
  # Calculates, stores, and retrieves stored signatures
  #
  # This class is meant to be subclassed, with the signed_contents method
  # overriden
  class Signer
    # @param key [String] name of git config key and signature history file
    # @param config [Overcommit::Configuration]
    def initialize(key, config)
      @key = key
      @config = config
    end

    # Return whether there is a stored signature for this key
    #
    # @return [true,false]
    def previous_signature?
      !stored_signature.empty?
    end

    # Return whether the signature for this hook has changed since it was last
    # calculated.
    #
    # @return [true,false]
    def signature_changed?
      changed = signature != stored_signature

      if changed && has_history_file
        changed = !signature_in_history_file(signature)
      end

      changed
    end

    # Update the current stored signature for this hook.
    def update_signature!
      updated_signature = signature

      result = Overcommit::Utils.execute(
        %w[git config --local] + [@key, updated_signature]
      )

      unless result.success?
        raise Overcommit::Exceptions::GitConfigError,
              "Unable to write to local repo git config: #{result.stderr}"
      end

      add_signature_to_history(updated_signature)
    end

    private

    def add_signature_to_history(signature)
      # Now we must update the history file with the new signature
      # We want to put the newest signatures at the top, since they are more
      # likely to be used, and will be read sooner
      signatures = []
      if has_history_file
        signatures = (File.readlines history_file).first(@config.signature_history - 1)
      else
        FileUtils.mkdir_p(File.dirname(history_file))
      end

      File.open(history_file, 'w') do |fh|
        fh.write("#{signature}\n")
        signatures.each do |old_signature|
          fh.write(old_signature)
        end
      end
    end

    def signature_in_history_file(signature)
      unless has_history_file
        return false
      end

      found = false
      File.open(history_file, 'r') do |fh|
        # Process the header
        until (line = fh.gets).nil?
          line.chomp

          if line == signature
            found = true
            break
          end
        end
      end

      found
    end

    # Does the history file exist
    def has_history_file
      File.exist?(history_file)
    end

    # Determine the absolute path for this signer's history file
    def history_file
      File.join(@config.signature_directory, @key)
    end

    def signature
      raise 'Subclass should implement signature'
    end

    def stored_signature
      result = Overcommit::Utils.execute(
        %w[git config --local --get] + [@key]
      )

      if result.status == 1 # Key doesn't exist
        return ''
      elsif result.status != 0
        raise Overcommit::Exceptions::GitConfigError,
              "Unable to read from local repo git config: #{result.stderr}"
      end

      result.stdout.chomp
    end
  end
end
