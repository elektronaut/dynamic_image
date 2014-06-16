# encoding: utf-8

module DynamicImage
  class ProcessedImage
    def initialize(record, format=nil)
      @record = record
      @format = format.to_s.upcase if format
    end

    def normalized
      require_valid_image!
      process_image
    end

    # def scaled_and_cropped(size)
    #   require_valid_image!
    #   process_image do |image|
    #     # Stuff
    #   end
    # end

    private

    def content_type_to_format(content_type)
      {
        'image/png'   => 'PNG',
        'image/gif'   => 'GIF',
        'image/jpeg'  => 'JPEG',
        'image/pjpeg' => 'JPEG',
        'image/tiff'  => 'TIFF'
      }[content_type]
    end

    def format
      @format || record_format
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

    def process_image(&block)
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
