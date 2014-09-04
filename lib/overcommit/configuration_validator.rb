module Overcommit
  # Validates and normalizes a configuration.
  class ConfigurationValidator
    # Validates hash for any invalid options, normalizing where possible.
    def validate(hash)
      hash = convert_nils_to_empty_hashes(hash)
      ensure_hook_type_sections_exist(hash)

      hash
    end

    private

    # Ensures that keys for all supported hook types exist (PreCommit,
    # CommitMsg, etc.)
    def ensure_hook_type_sections_exist(hash)
      Overcommit::Utils.supported_hook_type_classes.each do |hook_type|
        hash[hook_type] ||= {}
        hash[hook_type]['ALL'] ||= {}
      end
    end

    # Normalizes `nil` values to empty hashes.
    #
    # This is useful for when we want to merge two configuration hashes
    # together, since it's easier to merge two hashes than to have to check if
    # one of the values is nil.
    def convert_nils_to_empty_hashes(hash)
      hash.inject({}) do |h, (key, value)|
        h[key] =
          case value
          when nil  then {}
          when Hash then convert_nils_to_empty_hashes(value)
          else
            value
          end
        h
      end
    end
  end
end
