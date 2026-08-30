# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Processed Image
  #
  # Handles all processing of images.
  #
  # Results are cached as variants, so processing a size is expensive
  # once and cheap after that.
  #
  # @example
  #   size = DynamicImage::ImageSizing.new(image).fit("800x800")
  #   data = DynamicImage::ProcessedImage.new(image, format: :jpg)
  #                                      .cropped_and_resized(size)
  class ProcessedImage
    # @return [DynamicImage::Model] the image being processed
    attr_reader :record

    # @param record [DynamicImage::Model] the image to process
    # @param options [Hash]
    # @option options [Boolean] :uncropped Ignore any crop stored on the
    #   record
    # @option options [Symbol, String] :format Format to convert to.
    #   Defaults to the format of the stored image.
    def initialize(record, options = {})
      @record    = record
      @uncropped = options[:uncropped] ? true : false
      @format_name = options[:format].to_s.upcase if options[:format]
      @format_name = "JPEG" if defined?(@format_name) && @format_name == "JPG"
    end

    # Crops and resizes the image. Normalization is performed as well.
    #
    # @param size [Vector2d] the size to render, in pixels
    # @return [String] the image data as a binary string
    # @raise [DynamicImage::Errors::InvalidImage] if the record isn't a
    #   valid image
    #
    # @example
    #   processed = DynamicImage::ProcessedImage.new(image)
    #   image_data = processed.cropped_and_resized(Vector2d.new(200, 200))
    def cropped_and_resized(size)
      return crop_and_resize(size) unless record.persisted?

      find_or_create_variant(size).data
    end

    # Returns the variant for the given size, processing the image and
    # creating it if it doesn't already exist.
    #
    # @param size [Vector2d] the size to render, in pixels
    # @return [DynamicImage::Variant] the variant
    # @raise [DynamicImage::Errors::InvalidImage] if the record isn't a
    #   valid image
    def find_or_create_variant(size)
      find_variant(size) || create_variant(size)
    rescue ActiveRecord::RecordNotUnique
      find_variant(size)
    end

    # Find a variant with the given size.
    #
    # Variants whose data has gone missing from storage are destroyed
    # and treated as absent, so a lost blob heals on the next request.
    #
    # @param size [Vector2d] the size to look for, in pixels
    # @return [DynamicImage::Variant, nil] the variant, if one exists
    def find_variant(size)
      return nil unless record.persisted?

      variant = record.variants.find_by(variant_params(size))
      return nil unless variant

      if Dis::Storage.exists?(variant.class.dis_type, variant.content_hash)
        variant
      else
        variant.destroy
        nil
      end
    end

    # Find or create a variant for the given size, returning the variant
    # record rather than its data.
    #
    # @param size [Vector2d] the size to render, in pixels
    # @return [DynamicImage::Variant, nil] the variant, or nil if the
    #   record isn't persisted
    def variant_for(size)
      return nil unless record.persisted?

      find_or_create_variant(size)
    rescue ActiveRecord::RecordNotUnique
      find_variant(size)
    end

    # The format the image will be rendered in. This is the format given
    # to the constructor, falling back to the format of the stored
    # image.
    #
    # @return [DynamicImage::Format] the format
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
    # @yield [image] an optional block to transform the image before it
    #   is written out
    # @yieldparam image [DynamicImage::ImageProcessor] the processor
    # @yieldreturn [DynamicImage::ImageProcessor] the transformed
    #   processor
    # @return [String] the image data as a binary string
    # @raise [DynamicImage::Errors::InvalidImage] if the record isn't a
    #   valid image
    #
    # @example
    #   processed = DynamicImage::ProcessedImage.new(image, format: :jpeg)
    #   jpg_data = processed.normalized
    def normalized
      require_valid_image!

      record.with_data_file do |path|
        image = DynamicImage::ImageProcessor.new(path)
        image = yield(image) if block_given?
        image.convert(format).read
      end
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
