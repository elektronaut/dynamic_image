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
      format.content_type
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
      # TODO: dev test
      return crop_and_resize(size)

      return crop_and_resize(size) unless record.persisted?

      find_or_create_variant(size).tempfile
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
      process_data do |image|
        image = image.autorot if image.respond_to?(:autorot)
        image = convert_to_srgb(image)
        # TODO: convert profile
        image = yield(image) if block_given?
        # image = optimize(image)
        image

        # image.combine_options do |combined|
        #   # vips: image.autorot if image.respond_to?(:autorot)
        #   combined.auto_orient
        #   convert_to_srgb(image, combined)
        #   yield(combined) if block_given?
        #   optimize(combined)
        # end
        # # image.format(format) if needs_format_conversion?
      end
    end

    private

    # def coalesced(image)
    #   gif? ? DynamicImage::ImageReader.new(image.coalesce.to_blob).read : image
    # end

    def convert_to_srgb(image)
      # if image.data["profiles"].present? &&
      #    exif.colorspacedata&.strip&.downcase == record.colorspace
      #   combined.profile(srgb_profile)
      # end
      # combined.colorspace("sRGB") if record.cmyk?

      if image.get_fields.include?("icc-profile-data")
        # TODO: Check that we're converting within the same colorspace
        image.icc_transform("srgb")
      elsif record.cmyk?
        image.colourspace("srgb")
      else
        image
      end

      # image.colourspace("srgb")
    end

    def create_variant(size)
      record.variants.create(
        variant_params(size).merge(filename: record.filename,
                                   content_type: format.content_type,
                                   data: crop_and_resize(size))
      )
    end

    def crop_and_resize(size)
      normalized do |image|
        next unless record.cropped? || size != record.size

        crop_size, crop_start = image_sizing.crop_geometry(size)
        # ratio = size.x.to_f / crop_size.x
        # image.resize(ratio)

        # raise size.inspect

        image.crop(crop_start.x, crop_start.y, crop_size.x, crop_size.y)
             .thumbnail_image(size.x.to_i,
                              height: size.y.to_i, crop: :none, size: :both)
      end
    end

    def exif
      @exif ||= DynamicImage::ImageReader.new(record.tempfile).exif
    end

    # def gif?
    #   content_type == "image/gif"
    # end

    # def jpeg?
    #   content_type == "image/jpeg"
    # end

    def image_sizing
      @image_sizing ||=
        DynamicImage::ImageSizing.new(record, uncropped: @uncropped)
    end

    # def needs_format_conversion?
    #   format != record_format
    # end

    # def optimize(image)
    #   # TODO: Optimize here
    #   # image.layers "optimize" if gif?
    #   # image.strip
    #   # image.quality(85).sampling_factor("4:2:0").interlace("JPEG") if jpeg?
    #   image
    # end

    def process_data
      # image = coalesced(DynamicImage::ImageReader.new(record.tempfile).read)
      image = reader.read
      image = yield(image)
      # result = image.to_blob
      # image.destroy!
      # result

      tempfile = Tempfile.new(["dynamic_image", format.extension],
                              binmode: true)
      tempfile.close
      image.write_to_file(tempfile.path, **format.save_options)
      tempfile.open
      tempfile

      # image.write_to_buffer(format.extension)
    end

    def reader
      @reader ||= DynamicImage::ImageReader.new(record.tempfile)
    end

    def record_format
      DynamicImage::Format.content_type(record.content_type)
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
        format: format.name }
    end
  end
end
