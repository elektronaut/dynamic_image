# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Digest Verifier
  #
  # Signs and verifies the digests embedded in image URLs. The engine sets up the instance the application uses and
  # exposes it as <tt>DynamicImage.digest_verifier</tt>. The helpers sign with it and the controller verifies with
  # it, so there is rarely a reason to use this directly.
  #
  # Adapted from +ActiveSupport::MessageVerifier+, without the handling for arbitrary data structures and without
  # shipping the serialized data to the client.
  #
  # @example
  #   verifier = DynamicImage::DigestVerifier.new("super secret!")
  #   digest = verifier.generate("foo")
  #
  #   verifier.verify("foo", digest)
  #   # => true
  #   verifier.verify("bar", digest)
  #   # => raises DynamicImage::Errors::InvalidSignature
  class DigestVerifier
    # @param secret [String] the secret to sign with
    # @param options [Hash]
    # @option options [String] :digest the OpenSSL digest to use, defaults to "SHA1"
    def initialize(secret, options = {})
      @secret = secret
      @digest = options[:digest] || "SHA1"
    end

    # Generates a digest for a string.
    #
    # @param data [String] the string to sign
    # @return [String] the hex digest
    def generate(data)
      generate_digest(data)
    end

    # Verifies that <tt>digest</tt> is valid for <tt>data</tt>.
    #
    # @param data [String] the signed string
    # @param digest [String] the digest to check against
    # @return [true] if the digest is valid
    # @raise [DynamicImage::Errors::InvalidSignature] if it isn't
    def verify(data, digest)
      return true if valid_digest?(data, digest)

      raise DynamicImage::Errors::InvalidSignature
    end

    private

    def secure_compare?(str, other)
      return false unless str.bytesize == other.bytesize

      l = str.unpack "C#{str.bytesize}"

      res = 0
      other.each_byte { |byte| res |= byte ^ l.shift }
      res.zero?
    end

    def generate_digest(data)
      require "openssl" unless defined?(OpenSSL)
      OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.const_get(@digest).new,
        @secret,
        data
      )
    end

    def valid_digest?(data, digest)
      data.present? &&
        digest.present? &&
        secure_compare?(digest, generate_digest(data))
    end
  end
end
