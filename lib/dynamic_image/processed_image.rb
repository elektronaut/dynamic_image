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
      @format    = options[:format].to_s.upcase if options[:format]
      @format    = "JPEG" if defined?(@format) && @format == "JPG"
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

      record.variants.find_by(variant_params(size))
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
      process_data do |image|
        image.combine_options do |combined|
          combined.auto_orient
          convert_to_srgb(image, combined)
          yield(combined) if block_given?
          optimize(combined)
        end
        image.format(format) if needs_format_conversion?
      end
    end

    private

    def coalesced(image)
      gif? ? DynamicImage::ImageReader.new(image.coalesce.to_blob).read : image
    end

    def convert_to_srgb(image, combined)
      combined.profile(srgb_profile) if image.data["profiles"].present?
      combined.colorspace("sRGB") if record.cmyk?
    end

    def create_variant(size)
      record.variants.create(
        variant_params(size).merge(filename: record.filename,
                                   content_type: content_type,
                                   data: crop_and_resize(size))
      )
    end

    def crop_and_resize(size)
      normalized do |image|
        next unless record.cropped? || size != record.size

        image.crop(image_sizing.crop_geometry_string(size))
        image.resize(size)
      end
    end

    def format
      @format ||= record_format
    end

    def gif?
      content_type == "image/gif"
    end

    def jpeg?
      content_type == "image/jpeg"
    end

    def image_sizing
      @image_sizing ||=
        DynamicImage::ImageSizing.new(record, uncropped: @uncropped)
    end

    def needs_format_conversion?
      format != record_format
    end

    def optimize(image)
      image.layers "optimize" if gif?
      image.strip
      image.quality(85).sampling_factor("4:2:0").interlace("JPEG") if jpeg?
      image
    end

    def process_data
      image = coalesced(DynamicImage::ImageReader.new(record.data).read)
      yield(image)
      result = image.to_blob
      image.destroy!
      result
    end

    def record_format
      { "image/bmp" => "BMP", "image/png" => "PNG", "image/gif" => "GIF",
        "image/jpeg" => "JPEG", "image/pjpeg" => "JPEG", "image/tiff" => "TIFF",
        "image/webp" => "WEBP" }[record.content_type]
    end

    def require_valid_image!
      raise DynamicImage::Errors::InvalidImage unless record.valid?
    end

    def srgb_profile
      File.join(File.dirname(__FILE__), "profiles/sRGB_ICC_v4_Appearance.icc")
    end

    def variant_params(size)
      crop_size, crop_start = image_sizing.crop_geometry(size)

      { width: size.x.round, height: size.y.round,
        crop_width: crop_size.x, crop_height: crop_size.y,
        crop_start_x: crop_start.x, crop_start_y: crop_start.y,
        format: format }
    end
  end
end
