# encoding: utf-8

module DynamicImage
  class ProcessedImage
    def initialize(record, format=nil)
      @record = record
      @format = format.to_s.upcase if format
    end

    def cropped_and_resized(size)
      normalized do |image|
        image.crop image_sizing.crop_geometry_string(size)
        image.resize size
      end
    end

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
      @image_sizing ||= DynamicImage::ImageSizing.new(record)
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
        raise DynamicImage::Errors::InvalidImageError
      end
    end
  end
end
