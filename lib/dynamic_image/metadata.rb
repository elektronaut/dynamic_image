# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Metadata
  #
  # Parses metadata from an image. Expects to receive image data as a
  # binary string.
  class Metadata
    def initialize(data)
      @data = data
    end

    # Returns the color space of the image as a string. The result will be one
    # of the following: "rgb", "cmyk", "gray".
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
    def content_type
      reader.format.content_type if valid?
    end

    def format
      reader.format.name if valid?
    end

    # Returns the dimensions of the image as a vector.
    def dimensions
      Vector2d.new(metadata[:width], metadata[:height]) if valid?
    end

    # Returns the width of the image.
    def width
      metadata[:width] if valid?
    end

    # Returns the height of the image.
    def height
      metadata[:height] if valid?
    end

    # Returns true if the image is valid.
    def valid?
      @data && reader.valid_header? && metadata != :invalid
    end

    private

    def metadata
      @metadata ||= read_metadata
    end

    def read_image
      yield reader.read.autorot
    end

    def reader
      @reader ||= DynamicImage::ImageReader.new(@data)
    end

    def read_metadata
      read_image do |image|
        height = if image.get_fields.include?("page-height")
                   image.get("page-height")
                 else
                   image.get("height")
                 end

        { width: image.get("width"),
          height:,
          colorspace: image.get("interpretation") }
      end
    end
  end
end
