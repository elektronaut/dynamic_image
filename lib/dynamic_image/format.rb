# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Format
  #
  # A registry of the image formats DynamicImage understands. Each
  # format knows its content types, extensions, the magic bytes that
  # identify it, the options it is saved with, and whether it can hold
  # more than one frame.
  #
  # Formats are looked up by name, by content type, or by sniffing the
  # first bytes of a file. Uploads are always identified by sniffing,
  # never by the content type the client claims.
  #
  # @example
  #   DynamicImage::Format.find("jpg")           # => the JPEG format
  #   DynamicImage::Format.content_type("image/png")
  #   DynamicImage::Format.sniff(File.binread(path, 32))
  class Format
    # @!attribute [r] name
    #   @return [String] the format name, such as "JPEG"
    # @!attribute [r] animated
    #   @return [Boolean] whether the format holds more than one frame
    # @!attribute [r] alpha
    #   @return [Boolean] whether the format holds an alpha channel
    # @!attribute [r] content_types
    #   @return [Array<String>] the content types, canonical one first
    # @!attribute [r] extensions
    #   @return [Array<String>] the file extensions, preferred one first
    # @!attribute [r] magic_bytes
    #   @return [Array<String>] byte sequences identifying the format
    # @!attribute [r] offset
    #   @return [Integer] where in the header the magic bytes sit
    # @!attribute [r] save_options
    #   @return [Hash] options passed to vips when writing
    # @!attribute [r] signature
    #   @return [Proc, nil] an extra check against the header, for when
    #     the magic bytes alone are ambiguous
    attr_reader :name, :animated, :alpha, :content_types, :extensions,
                :magic_bytes, :offset, :save_options, :signature

    # @param name [String] the format name
    # @param options [Hash] the format definition, as passed to
    #   {Format.register}
    # @see Format.register
    def initialize(name, options)
      options = default_options.merge(options)

      @name = name
      @animated = options[:animated]
      @alpha = options[:alpha]
      @content_types = Array(options[:content_type])
      @extensions = Array(options[:extension])
      @magic_bytes = options[:magic_bytes].map(&:b)
      @offset = options[:offset]
      @signature = options[:signature]
      @save_options = options[:save_options]
    end

    # Returns true if the format supports multiple frames.
    #
    # @return [Boolean]
    def animated?
      animated
    end

    # Returns true if the format supports an alpha channel.
    #
    # @return [Boolean]
    def alpha?
      alpha
    end

    # Returns true if the given header belongs to this format.
    #
    # @param bytes [String] the first bytes of the file
    # @return [Boolean]
    def matches?(bytes)
      header = bytes.to_s[offset..].to_s
      return false unless magic_bytes.any? { |b| header.start_with?(b) }

      signature.nil? || signature.call(bytes)
    end

    # The canonical content type.
    #
    # @return [String] the content type
    def content_type
      content_types.first
    end

    # The preferred file extension, leading dot included.
    #
    # @return [String] the extension
    def extension
      extensions.first
    end

    class << self
      # Finds the format for a content type.
      #
      # @param type [String] the content type
      # @return [DynamicImage::Format, nil] the format
      def content_type(type)
        formats.filter { |f| f.content_types.include?(type) }.first
      end

      # Every content type of every registered format.
      #
      # @return [Array<String>] the content types
      def content_types
        formats.flat_map(&:content_types)
      end

      # Finds a format by name. Case insensitive, and "JPG" is
      # understood as an alias for "JPEG".
      #
      # @param name [String, Symbol] the format name
      # @return [DynamicImage::Format, nil] the format
      def find(name)
        key = name.to_s.upcase
        key = "JPEG" if key == "JPG"
        registered_formats[key]
      end

      # All registered formats.
      #
      # @return [Array<DynamicImage::Format>] the formats
      def formats
        registered_formats.map { |_, f| f }
      end

      # Registers a format.
      #
      # Each option sets the attribute of the same name, except
      # +content_type+ and +extension+, which are singular here and
      # accept either one value or a list. Anything left out falls back
      # to {Format#default_options}.
      #
      # @param name [String] the format name, uppercase by convention
      # @param opts [Hash] the format definition
      # @return [DynamicImage::Format] the registered format
      def register(name, **opts)
        registered_formats[name] = new(name, opts)
      end

      # Identifies a format from the first bytes of a file.
      #
      # @param bytes [String, nil] the file header
      # @return [DynamicImage::Format, nil] the format, if recognized
      def sniff(bytes)
        return unless bytes

        formats.find { |format| format.matches?(bytes) }
      end

      # The brands declared by an ISO base media file, major brand
      # first, followed by the compatible brands. Empty for anything
      # that isn't an +ftyp+ box.
      #
      # @param bytes [String] the file header
      # @return [Array<String>] the brands
      def iso_brands(bytes)
        return [] unless bytes.to_s.bytesize >= 12 && bytes[4, 4] == "ftyp".b

        [bytes[8, 4]] + bytes[16...bytes.unpack1("N")].to_s.scan(/.{4}/m)
      end

      private

      def registered_formats
        @registered_formats ||= {}
      end
    end

    # Defaults every format definition is merged over.
    #
    # @return [Hash] the default options
    def default_options
      { animated: false, alpha: false, content_type: [], extension: [],
        magic_bytes: [], offset: 0, signature: nil, save_options: {} }
    end

    register(
      "AVIF",
      animated: true,
      alpha: true,
      content_type: %w[image/avif],
      extension: %w[.avif],
      offset: 4,
      magic_bytes: %w[ftyp],
      signature: ->(bytes) { iso_brands(bytes).intersect?(%w[avif avis]) }
    )

    register(
      "BMP",
      content_type: %w[image/bmp],
      extension: %w[.bmp],
      magic_bytes: ["\x42\x4d"]
    )

    register(
      "GIF",
      animated: true,
      alpha: true,
      content_type: %w[image/gif],
      extension: %w[.gif],
      magic_bytes: %w[GIF87a GIF89a]
    )

    register(
      "HEIC",
      animated: true,
      alpha: true,
      content_type: %w[image/heic image/heif],
      extension: %w[.heic .heif],
      offset: 4,
      magic_bytes: %w[ftyp],
      signature: lambda { |bytes|
        iso_brands(bytes).intersect?(
          %w[heic heix hevc hevx heim heis hevm hevs mif1 msf1]
        )
      }
    )

    register(
      "JPEG",
      content_type: %w[image/jpeg image/pjpeg],
      extension: %w[.jpg .jpeg],
      magic_bytes: ["\xff\xd8"],
      save_options: { Q: 90, strip: true, background: [255.0, 255.0, 255.0] }
    )

    register(
      "JXL",
      alpha: true,
      content_type: %w[image/jxl],
      extension: %w[.jxl],
      magic_bytes: ["\xff\x0a", "\x00\x00\x00\x0cJXL \r\n\x87\n"],
      save_options: { Q: 75, effort: 3, strip: true }
    )

    register(
      "PNG",
      alpha: true,
      content_type: %w[image/png],
      extension: %w[.png],
      magic_bytes: ["\x89\x50\x4e\x47\x0d\x0a\x1a\x0a"]
    )

    register(
      "TIFF",
      alpha: true,
      content_type: %w[image/tiff],
      extension: %w[.tiff .tif],
      magic_bytes: ["\x49\x49\x2a\x00", "\x4d\x4d\x00\x2a"]
    )

    register(
      "WEBP",
      animated: true,
      alpha: true,
      content_type: %w[image/webp],
      extension: %w[.webp],
      magic_bytes: ["\x52\x49\x46\x46"],
      signature: ->(bytes) { bytes.bytesize >= 12 && bytes[8, 4] == "WEBP" },
      save_options: { Q: 90, strip: true }
    )
  end
end
