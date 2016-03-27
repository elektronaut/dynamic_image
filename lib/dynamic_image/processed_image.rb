# encoding: utf-8

module DynamicImage
  # = DynamicImage Processed Image
  #
  # Handles all processing of images. Takes an instance of
  # +DynamicImage::Model+ as argument.
  class ProcessedImage
    def initialize(record, options = {})
      @record    = record
      @uncropped = options[:uncropped] ? true : false
      @format    = options[:format].to_s.upcase if options[:format]
      @format    = 'JPEG' if defined?(@format) && @format == 'JPG'
    end

    # Returns the content type of the processed image.
    #
    # ==== Example
    #
    #   image = Image.find(params[:id])
    #   DynamicImage::ProcessedImage.new(image).content_type
    #   # => 'image/png'
    #   DynamicImage::ProcessedImage.new(image, :jpeg).content_type
    #   # => 'image/jpeg'
    def content_type
      "image/#{format}".downcase
    end

    # Crops and resizes the image. Normalization is performed as well.
    #
    # ==== Example
    #
    #   processed = DynamicImage::ProcessedImage.new(image)
    #   image_data = processed.cropped_and_resized(Vector2d.new(200, 200))
    #
    # Returns a binary string.
    def cropped_and_resized(size)
      normalized do |image|
        if record.cropped? || size != record.size
          image.crop(image_sizing.crop_geometry_string(size))
          image.resize(size)
        end
      end
    end

    # Normalizes the image.
    #
    # * Applies EXIF rotation
    # * CMYK images are converted to sRGB
    # * Strips metadata
    # * Optimizes GIFs
    # * Performs format conversion if the requested format is different
    #
    # ==== Example
    #
    #   processed = DynamicImage::ProcessedImage.new(image, :jpeg)
    #   jpg_data = processed.normalized
    #
    # Returns a binary string.
    def normalized
      require_valid_image!
      process_data do |image|
        image.combine_options do |combined|
          combined.auto_orient
          combined.colorspace('sRGB') if needs_colorspace_conversion?
          yield(combined) if block_given?
          optimize(combined)
        end
        image.format(format) if needs_format_conversion?
      end
    end

    private

    def coalesced(image)
      if gif?
        image.coalesce
        image = DynamicImage::ImageReader.new(image.to_blob).read
      end
      image
    end

    def format
      @format ||= record_format
    end

    def gif?
      content_type == 'image/gif'
    end

    def image_sizing
      @image_sizing ||= DynamicImage::ImageSizing.new(record,
                                                      uncropped: @uncropped)
    end

    def needs_colorspace_conversion?
      record.cmyk?
    end

    def needs_format_conversion?
      format != record_format
    end

    def optimize(image)
      image.layers 'optimize' if gif?
      image.strip
    end

    def process_data
      image = coalesced(DynamicImage::ImageReader.new(record.data).read)
      yield(image)
      result = image.to_blob
      image.destroy!
      result
    end

    attr_reader :record

    def record_format
      case record.content_type
      when 'image/png'
        'PNG'
      when 'image/gif'
        'GIF'
      when 'image/jpeg', 'image/pjpeg'
        'JPEG'
      when 'image/tiff'
        'TIFF'
      end
    end

    def require_valid_image!
      raise DynamicImage::Errors::InvalidImage unless record.valid?
    end
  end
end
