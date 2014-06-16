# encoding: utf-8

module DynamicImage
  class ProcessedImage
    def initialize(record, format=nil)
      @record = record
      @format = format.to_s.upcase if format
    end

    def crop_geometry(size)
      crop_size, start = crop_geometry_vectors(size)
      crop_size.to_s + "+#{start.x.to_i}+#{start.y.to_i}"
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

    def crop_geometry_vectors(size)
      # Maximize the crop area to fit the image size
      crop_size = size.fit(record.size).round

      # Ignore pixels outside the pre-cropped area for now
      center = record.crop_gravity - record.crop_start

      # Start at center
      start = center - (crop_size / 2).floor

      # Adjust if the cropping is out of bounds
      start += shift_vector(start)
      start -= shift_vector(record.size - (start + crop_size))

      [crop_size, (start + record.crop_start)]
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

    def shift_vector(vect)
      vector(
        vect.x < 0 ? vect.x.abs : 0,
        vect.y < 0 ? vect.y.abs : 0
      )
    end

    def vector(x, y)
      Vector2d.new(x, y)
    end
  end
end
