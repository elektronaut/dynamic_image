# encoding: utf-8

module DynamicImage
  # = DynamicImage Processed Image
  #
  # Handles all processing of images. Takes an instance of
  # +DynamicImage::Model+ as argument.
  class ProcessedImage
    def initialize(record, options={})
      @record    = record
      @uncropped = options[:uncropped] ? true : false
      @format    = options[:format].to_s.upcase if options[:format]
      @format    = "JPEG" if @format == "JPG"
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
        image.crop image_sizing.crop_geometry_string(size)
        image.resize size
        if content_type == 'image/gif'
          image.coalesce
        end
      end
    end

    # Normalizes the image.
    #
    # * Applies EXIF rotation
    # * CMYK images are converted to sRGB
    # * Strips metadata
    # * Performs format conversion if the requested format is different
    #
    # ==== Example
    #
    #   processed = DynamicImage::ProcessedImage.new(image, :jpeg)
    #   jpg_data = processed.normalized
    #
    # Returns a binary string.
    def normalized(&block)
      require_valid_image!
      process_data do |image|
        image.combine_options do |combined|
          image.auto_orient
          image.colorspace('sRGB') if needs_colorspace_conversion?
          yield(combined) if block_given?
          image.strip
        end
        image.format(format) if needs_format_conversion?
      end
    end

    private

    def format
      @format || record_format
    end

    def image_sizing
      @image_sizing ||= DynamicImage::ImageSizing.new(record, uncropped: @uncropped)
    end

    def needs_colorspace_conversion?
      record.cmyk?
    end

    def needs_format_conversion?
      format != record_format
    end

    def process_data(&block)
      image = MiniMagick::Image.read(record.data)
      yield(image)
      result = image.to_blob
      image.destroy!
      result
    end

    def record
      @record
    end

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
      unless record.valid?
        raise DynamicImage::Errors::InvalidImage
      end
    end
  end
end
