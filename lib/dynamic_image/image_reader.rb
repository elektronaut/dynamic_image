# encoding: utf-8

module DynamicImage
  class ImageReader
    def initialize(data)
      @data = data
    end

    def read
      raise DynamicImage::Errors::InvalidHeader unless valid_header?
      MiniMagick::Image.read(@data)
    end

    def valid_header?
      magic_bytes.each do |expr|
        if (expr.is_a?(Regexp) && file_header =~ /^#{expr}/) ||
           (expr.is_a?(String) && file_header.start_with?(expr))
          return true
        end
      end
      false
    end

    private

    def file_header
      @file_header ||= StringIO.new(@data, "rb").read(10)
    end

    def magic_bytes
      [
        # GIF
        "\x47\x49\x46\x38\x37\x61".force_encoding("binary"),
        "\x47\x49\x46\x38\x39\x61".force_encoding("binary"),
        # PNG
        "\x89\x50\x4e\x47\x0d\x0a\x1a\x0a".force_encoding("binary"),
        # JPEG
        "\xff\xd8\xff\xdb".force_encoding("binary"),
        Regexp.new("\xff\xd8\xff\xe0(.*){2}JFIF".force_encoding("binary")),
        Regexp.new("\xff\xd8\xff\xe1(.*){2}Exif".force_encoding("binary")),
        "\xff\xd8\xff\xee\x00\x0e".force_encoding("binary"), # Adobe JPEG
        # TIFF
        "\x49\x49\x2a\x00".force_encoding("binary"),
        "\x4d\x4d\x00\x2a".force_encoding("binary"),
      ]
    end
  end
end