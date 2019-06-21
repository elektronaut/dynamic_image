# frozen_string_literal: true

module DynamicImage
  class ImageReader
    class << self
      def magic_bytes
        @magic_bytes ||= [
          "\x47\x49\x46\x38\x37\x61",         # GIF
          "\x47\x49\x46\x38\x39\x61",
          "\x89\x50\x4e\x47\x0d\x0a\x1a\x0a", # PNG
          "\xff\xd8",                         # JPEG
          "\x49\x49\x2a\x00",                 # TIFF
          "\x4d\x4d\x00\x2a",
          "\x42\x4d"                          # BMP
        ].map { |s| s.dup.force_encoding("binary") }
      end
    end

    def initialize(data)
      @data = data
    end

    def read
      raise DynamicImage::Errors::InvalidHeader unless valid_header?

      MiniMagick::Image.read(@data)
    end

    def valid_header?
      return false if file_header.blank?

      self.class.magic_bytes.each do |str|
        return true if file_header.start_with?(str)
      end
      false
    end

    private

    def file_header
      @file_header ||= StringIO.new(@data, "rb").read(8)
    end
  end
end
