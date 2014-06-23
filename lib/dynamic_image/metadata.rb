# encoding: utf-8

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
      if valid?
        case metadata[:colorspace]
        when /rgb/i
          "rgb"
        when /cmyk/i
          "cmyk"
        when /gray/i
          "gray"
        end
      end
    end

    # Returns the content type of the image.
    def content_type
      if valid?
        "image/#{format.downcase}"
      end
    end

    # Returns the dimensions of the image as a vector.
    def dimensions
      if valid?
        Vector2d.new(*metadata[:dimensions])
      end
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
      if valid?
        metadata[:format]
      end
    end

    # Returns true if the image is valid.
    def valid?
      @data && metadata != :invalid
    end

    private

    def metadata
      @metadata ||= read_metadata
    end

    def read_metadata
      image = MiniMagick::Image.read(@data)
      image.auto_orient
      metadata = {
        colorspace: image[:colorspace],
        dimensions: image[:dimensions],
        format:     image[:format]
      }
      image.destroy!
      metadata
    rescue MiniMagick::Invalid
      :invalid
    end
  end
end