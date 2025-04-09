# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Processed Image
  #
  # Handles all processing of images. Takes an instance of
  # +DynamicImage::Model+ as argument.
  class ProcessedImage
    attr_reader :record

    def initialize(record, options = {})
      @record    = record
      @uncropped = options[:uncropped] ? true : false
      @format_name = options[:format].to_s.upcase if options[:format]
      @format_name = "JPEG" if defined?(@format_name) && @format_name == "JPG"
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
      return crop_and_resize(size) unless record.persisted?

      find_or_create_variant(size).data
    end

    # Find or create a variant with the given size.
    def find_or_create_variant(size)
      find_variant(size) || create_variant(size)
    rescue ActiveRecord::RecordNotUnique
      find_variant(size)
    end

    # Find a variant with the given size.
    def find_variant(size)
      return nil unless record.persisted?

      variant = record.variants.find_by(variant_params(size))
      variant&.tap(&:data)
    rescue Dis::Errors::NotFoundError
      variant.destroy
      nil
    end

    def format
      DynamicImage::Format.find(@format_name) || record_format
    end

    # Normalizes the image.
    #
    # * Applies EXIF rotation
    # * Converts to sRGB
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

      image = DynamicImage::ImageProcessor.new(record.data)
      image = yield(image) if block_given?
      image.convert(format).read
    end

    private

    def create_variant(size)
      record.variants.create(
        variant_params(size).merge(filename: record.filename,
                                   content_type: format.content_type,
                                   data: crop_and_resize(size))
      )
    end

    def crop_and_resize(size)
      normalized do |image|
        image.crop(*image_sizing.crop_geometry(size)).resize(size)
      end
    end

    def image_sizing
      @image_sizing ||=
        DynamicImage::ImageSizing.new(record, uncropped: @uncropped)
    end

    def record_format
      DynamicImage::Format.content_type(record.content_type)
    end

    def require_valid_image!
      raise DynamicImage::Errors::InvalidImage unless record.valid?
    end

    def variant_params(size)
      crop_size, crop_start = image_sizing.crop_geometry(size)

      { width: size.x.round, height: size.y.round,
        crop_width: crop_size.x, crop_height: crop_size.y,
        crop_start_x: crop_start.x, crop_start_y: crop_start.y,
        format: format.name }
    end
  end
end
