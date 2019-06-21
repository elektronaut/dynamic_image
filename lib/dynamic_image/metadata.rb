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

      case metadata[:colorspace]
      when /rgb/i
        "rgb"
      when /cmyk/i
        "cmyk"
      when /gray/i
        "gray"
      end
    end

    # Returns the content type of the image.
    def content_type
      "image/#{format.downcase}" if valid?
    end

    # Returns the dimensions of the image as a vector.
    def dimensions
      Vector2d.new(*metadata[:dimensions]) if valid?
    end

    # Returns the width of the image.
    def width
      dimensions.try(:x)
    end

    # Returns the height of the image.
    def height
      dimensions.try(:y)
    end

    # Returns the format of the image.
    def format
      metadata[:format] if valid?
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
      image = reader.read
      image.auto_orient
      result = yield image
      image.destroy!
      result
    rescue MiniMagick::Invalid
      :invalid
    end

    def reader
      @reader ||= DynamicImage::ImageReader.new(@data)
    end

    def read_metadata
      read_image do |image|
        {
          colorspace: image[:colorspace],
          dimensions: image[:dimensions],
          format: image[:format]
        }
      end
    end
  end
end
