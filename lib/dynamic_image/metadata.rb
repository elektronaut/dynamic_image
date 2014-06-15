# encoding: utf-8

module DynamicImage
  class Metadata
    def initialize(data)
      @data = data
    end

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

    def content_type
      if valid?
        "image/#{format.downcase}"
      end
    end

    def dimensions
      if valid?
        Vector2d.new(*metadata[:dimensions])
      end
    end

    def width
      dimensions.try(:x)
    end

    def height
      dimensions.try(:y)
    end

    def format
      if valid?
        metadata[:format]
      end
    end

    def valid?
      metadata != :invalid
    end

    private

    def metadata
      @metadata ||= read_metadata
    end

    def read_metadata
      image = MiniMagick::Image.read(@data)
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