# encoding: utf-8

module DynamicImage
  # = DynamicImage Digest Verifier
  #
  # ==== Usage
  #
  #   verifier = DynamicImage::DigestVerifier.new("super secret!")
  #
  #   digest = verifier.generate("foo")
  #
  #   digest.verify("foo", digest)
  #   # => true
  #   digest.verify("bar", digest)
  #   # => raises DynamicImage::Errors::InvalidSignature
  #
  # Credit where credit is due: adapted and simplified from
  # +ActiveSupport::MessageVerifier+, since we don't need to handle
  # arbitrary data structures and ship the serialized data to the client.
  class DigestVerifier
    def initialize(secret, options = {})
      @secret = secret
      @digest = options[:digest] || 'SHA1'
    end

    # Generates a digest for a string.
    def generate(data)
      generate_digest(data)
    end

    # Verifies that <tt>digest</tt> is valid for <tt>data</tt>.
    # Raises a +DynamicImage::Errors::InvalidSignature+ error if not.
    def verify(data, digest)
      if valid_digest?(data, digest)
        true
      else
        raise DynamicImage::Errors::InvalidSignature
      end
    end

    private

    def secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      l = a.unpack "C#{a.bytesize}"

      res = 0
      b.each_byte { |byte| res |= byte ^ l.shift }
      res == 0
    end

    def generate_digest(data)
      require 'openssl' unless defined?(OpenSSL)
      OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.const_get(@digest).new,
        @secret,
        data
      )
    end

    def valid_digest?(data, digest)
      data.present? &&
        digest.present? &&
        secure_compare(digest, generate_digest(data))
    end
  end
end
