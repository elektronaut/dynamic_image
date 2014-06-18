# encoding: utf-8

module DynamicImage
  # Adapted from ActiveSupport::MessageVerifier
  class DigestVerifier
    def initialize(secret, options = {})
      @secret = secret
      @digest = options[:digest] || 'SHA1'
    end

    def generate(data)
      generate_digest(data)
    end

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
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.const_get(@digest).new, @secret, data)
    end

    def valid_digest?(data, digest)
      data.present? && digest.present? && secure_compare(digest, generate_digest(data))
    end
  end
end