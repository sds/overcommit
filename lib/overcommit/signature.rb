# frozen_string_literal: true

require 'digest'

module Overcommit
  # Calculates, stores, and retrieves stored signatures of git objects.
  module Signature
    # Calculates the signature of some _String_.
    #
    # @param arg [String]
    # @return [String]
    def self.sign(arg)
      Digest::SHA256.hexdigest(arg)
    end

    # Calculates the signature of some _Hash_.
    #
    # @param arg [Hash]
    # @return [String]
    def self.sign_signatures(arg)
      sign(to_blob(arg))
    end

    # Returns the object signature for some blob.
    #
    # @return [Hash]
    def self.object_signature(blob)
      { Overcommit::GitRepo.blob_id(blob) => sign(blob) }
    end

    # Stores the object signatures as verified.
    #
    # @param object_signatures [Hash] a hash of git object hashes to their signatures
    def self.verify(object_signatures)
      blob = to_blob(object_signatures)
      Overcommit::GitRepo.blob_id(blob, write: true)
    end

    # Have the given object signatures been verified?
    #
    # @param object_signatures [Hash] a hash of git object hashes to their signatures
    # @return [true,false]
    def self.verified?(object_signatures)
      blob = to_blob(object_signatures)
      object_signatures_id = Overcommit::GitRepo.blob_id(blob)
      existing_blob = Overcommit::GitRepo.blob_contents(object_signatures_id)
      # Compare the contents in case of a SHA1 collision.
      existing_blob == blob
    end

    private

    # Converts a Hash of git object hashes and their signatures to a signature blob.
    #
    # @example
    # rubocop:disable Metrics/LineLength
    # Converts from:
    #   {
    #     "333EC19DD1707BA9D10EB18913C7214D701691BB" => "2938858697BE5C7552CD9463DA010E01F01AC3B8AD65FE584975CE4F2FFC1E7E",
    #     "426637B5CCDA600060C504CCB133D1976576E594" => "9526B9B463BDC1E856C12518998C704D070C0C217F2896959DB22DBEE7345684"
    #   }
    # to:
    #   <<~SIGNATURES.chomp
    #     333EC19DD1707BA9D10EB18913C7214D701691BB 2938858697BE5C7552CD9463DA010E01F01AC3B8AD65FE584975CE4F2FFC1E7E
    #     426637B5CCDA600060C504CCB133D1976576E594 9526B9B463BDC1E856C12518998C704D070C0C217F2896959DB22DBEE7345684
    #   SIGNATURES
    # rubocop:enable Metrics/LineLength
    #
    # @param object_signatures [Hash]
    # @return [String]
    def self.to_blob(object_signatures)
      lines = object_signatures.map do |git_object_hash, signature|
        "#{git_object_hash} #{signature}"
      end
      lines.join("\n")
    end

    # Converts a signature blob to a Hash of git object hashes and their signatures.
    #
    # @example
    # rubocop:disable Metrics/LineLength
    # Converts from:
    #   <<~SIGNATURES.chomp
    #     333EC19DD1707BA9D10EB18913C7214D701691BB 2938858697BE5C7552CD9463DA010E01F01AC3B8AD65FE584975CE4F2FFC1E7E
    #     426637B5CCDA600060C504CCB133D1976576E594 9526B9B463BDC1E856C12518998C704D070C0C217F2896959DB22DBEE7345684
    #   SIGNATURES
    # to:
    #   {
    #     "333EC19DD1707BA9D10EB18913C7214D701691BB" => "2938858697BE5C7552CD9463DA010E01F01AC3B8AD65FE584975CE4F2FFC1E7E",
    #     "426637B5CCDA600060C504CCB133D1976576E594" => "9526B9B463BDC1E856C12518998C704D070C0C217F2896959DB22DBEE7345684"
    #   }
    # rubocop:enable Metrics/LineLength
    #
    # @param blob [String]
    # @return [Hash]
    def self.to_hash(blob)
      Hash[blob.split('\n').each_slice.map { |line| line.split(' ') }]
    end
  end
end
