# frozen_string_literal: true

module DynamicImage
  class Format
    attr_reader :name, :animated, :content_types, :extensions, :magic_bytes,
                :save_options

    def initialize(name, options)
      options = default_options.merge(options)

      @name = name
      @animated = options[:animated]
      @content_types = Array(options[:content_type])
      @extensions = Array(options[:extension])
      @magic_bytes = options[:magic_bytes].map do |s|
        s.dup.force_encoding("binary")
      end
      @save_options = options[:save_options]
    end

    def animated?
      animated
    end

    def content_type
      content_types.first
    end

    def extension
      extensions.first
    end

    class << self
      def content_type(type)
        formats.filter { |f| f.content_types.include?(type) }.first
      end

      def content_types
        formats.flat_map(&:content_types)
      end

      def find(name)
        key = name.to_s.upcase
        key = "JPEG" if key == "JPG"
        registered_formats[key]
      end

      def formats
        registered_formats.map { |_, f| f }
      end

      def register(name, **opts)
        registered_formats[name] = new(name, opts)
      end

      def sniff(bytes)
        return unless bytes

        formats.each do |format|
          format.magic_bytes.each do |b|
            return format if bytes.start_with?(b)
          end
        end
        nil
      end

      private

      def registered_formats
        @registered_formats ||= {}
      end
    end

    def default_options
      { animated: false, content_type: [], extension: [], magic_bytes: [],
        save_options: {} }
    end

    register(
      "BMP",
      content_type: %w[image/bmp],
      extension: %w[.bmp],
      magic_bytes: ["\x42\x4d"]
    )

    register(
      "GIF",
      animated: true,
      content_type: %w[image/gif],
      extension: %w[.gif],
      magic_bytes: %w[GIF87a GIF89a]
    )

    register(
      "JPEG",
      content_type: %w[image/jpeg image/pjpeg],
      extension: %w[.jpg .jpeg],
      magic_bytes: ["\xff\xd8"],
      save_options: { Q: 90, strip: true, background: [255.0, 255.0, 255.0] }
    )

    register(
      "PNG",
      content_type: %w[image/png],
      extension: %w[.png],
      magic_bytes: ["\x89\x50\x4e\x47\x0d\x0a\x1a\x0a"]
    )

    register(
      "TIFF",
      content_type: %w[image/tiff],
      extension: %w[.tiff .tif],
      magic_bytes: ["\x49\x49\x2a\x00", "\x4d\x4d\x00\x2a"]
    )

    register(
      "WEBP",
      animated: true,
      content_type: %w[image/webp],
      extension: %w[.webp],
      magic_bytes: ["\x52\x49\x46\x46"],
      save_options: { Q: 90, strip: true }
    )
  end
end
