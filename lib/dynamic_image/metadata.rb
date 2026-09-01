# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Metadata
  #
  # Parses metadata from an image. Accepts a Pathname, IO, or binary string.
  #
  # Every reader returns nil for data that isn't a readable image.
  #
  # @example
  #   metadata = DynamicImage::Metadata.new(Pathname.new("image.jpg"))
  #   metadata.valid?       # => true
  #   metadata.content_type # => "image/jpeg"
  #   metadata.dimensions   # => Vector2d(320, 200)
  class Metadata
    # @param data [Pathname, IO, String] the image, as a path, an open file or a binary string
    def initialize(data)
      @data = data
    end

    # Returns the color space of the image as a string. The result will be one of the following: "rgb", "cmyk",
    # "gray".
    #
    # @return [String, nil]
    def colorspace
      return unless valid?

      case metadata[:colorspace].to_s
      when /rgb/i
        "rgb"
      when /cmyk/i
        "cmyk"
      when /gray/i, /b-w/i
        "gray"
      end
    end

    # Returns the content type of the image.
    #
    # @return [String, nil]
    def content_type
      reader.format.content_type if valid?
    end

    # Returns the name of the detected format.
    #
    # @return [String, nil] the format name, such as "JPEG"
    def format
      reader.format.name if valid?
    end

    # Returns the dimensions of the image as a vector. EXIF rotation is applied, so these are the dimensions the
    # image has once normalized.
    #
    # @return [Vector2d, nil]
    def dimensions
      Vector2d.new(metadata[:width], metadata[:height]) if valid?
    end

    # Returns the width of the image.
    #
    # @return [Integer, nil] the width in pixels
    def width
      metadata[:width] if valid?
    end

    # Returns the height of the image.
    #
    # @return [Integer, nil] the height in pixels
    def height
      metadata[:height] if valid?
    end

    # Returns the number of frames. Animated formats can have more than one; everything else has a single frame.
    #
    # @return [Integer, nil] the number of frames
    def frame_count
      metadata[:frame_count] if valid?
    end

    # Returns true if the image has an alpha channel.
    #
    # This is the presence of the channel, not of actual transparency: an image can carry a fully opaque alpha
    # channel. Reading it costs nothing, where scanning the channel for transparency would mean decoding every pixel.
    #
    # @return [Boolean, nil] true if the image has an alpha channel
    def alpha?
      metadata[:alpha] if valid?
    end

    # Returns true if the data is a readable image in a supported format.
    #
    # @return [Boolean]
    def valid?
      @data && reader.valid_header? && metadata != :invalid
    end

    private

    def metadata
      @metadata ||= read_metadata
    end

    def reader
      @reader ||= DynamicImage::ImageReader.new(@data)
    end

    def read_metadata
      image = reader.read
      width, height = dimensions_from(image)
      width, height = height, width if rotated?(image)
      { width:, height:,
        colorspace: image.get("interpretation"),
        frame_count: frame_count_from(image),
        alpha: image.has_alpha? }
    rescue Vips::Error
      :invalid
    end

    def frame_count_from(image)
      return 1 unless image.get_fields.include?("n-pages")

      image.get("n-pages")
    end

    def dimensions_from(image)
      width = image.get("width")
      height = if image.get_fields.include?("page-height")
                 image.get("page-height")
               else
                 image.get("height")
               end
      [width, height]
    end

    def orientation(image)
      return 1 unless image.get_fields.include?("orientation")

      image.get("orientation")
    rescue Vips::Error
      1
    end

    def rotated?(image)
      orientation(image).between?(5, 8)
    end
  end
end
