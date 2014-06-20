# encoding: utf-8

module DynamicImage
  # = DynamicImage Image Sizing
  #
  # Calculates cropping and fitting for image sizes.
  class ImageSizing
    def initialize(record, options={})
      @record = record
      @uncropped = options[:uncropped] ? true : false
    end

    # Calculates crop geometry. The given vector is scaled
    # to match the image size, since DynamicImage performs
    # cropping before resizing.
    #
    # ==== Example
    #
    #   image = Image.find(params[:id]) # 320x200 image
    #   sizing = DynamicImage::ImageSizing.new(image)
    #
    #   sizing.crop_geometry(Vector2d(100, 100))
    #   # => [Vector2d(200, 200), Vector2d(60, 0)]
    #
    # Returns a tuple with crop size and crop start vectors.
    def crop_geometry(ratio_vector)
      # Maximize the crop area to fit the image size
      crop_size = ratio_vector.fit(size).round

      # Ignore pixels outside the pre-cropped area for now
      center = crop_gravity - crop_start

      start = center - (crop_size / 2).floor
      start = clamp(start, crop_size, size)

      [crop_size, (start + crop_start)]
    end

    # Returns crop geometry as an ImageMagick compatible string.
    #
    # ==== Example
    #
    #   image = Image.find(params[:id]) # 320x200 image
    #   sizing = DynamicImage::ImageSizing.new(image)
    #
    #   sizing.crop_geometry(Vector2d(100, 100)) # => "200x200+60+0"
    def crop_geometry_string(ratio_vector)
      crop_size, start = crop_geometry(ratio_vector)
      crop_size.floor.to_s + "+#{start.x.to_i}+#{start.y.to_i}"
    end

    # Adjusts +fit_size+ to fit the image dimensions.
    # Any dimension set to zero will be ignored.
    #
    # ==== Options
    #
    # * <tt>:crop</tt> - Don't keep aspect ratio. This will allow
    #   the image to be cropped to the requested size.
    # * <tt>:upscale</tt> - Don't limit to the size of the image.
    #   Images smaller than the given size will be scaled up.
    #
    # ==== Examples
    #
    #   image = Image.find(params[:id]) # 320x200 image
    #   sizing = DynamicImage::ImageSizing.new(image)
    #
    #   sizing.fit(Vector2d(0, 100))
    #   # => Vector2d(160.0, 100.0)
    #
    #   sizing.fit(Vector2d(500, 500))
    #   # => Vector2d(320.0, 200.0)
    #
    #   sizing.fit(Vector2d(500, 500), crop: true)
    #   # => Vector2d(200.0, 200.0)
    #
    #   sizing.fit(Vector2d(500, 500), upscale: true)
    #   # => Vector2d(500.0, 312.5)
    #
    def fit(fit_size, options={})
      fit_size = parse_vector(fit_size)
      require_dimensions!(fit_size)     if options[:crop]
      fit_size = size.fit(fit_size)     unless options[:crop]
      fit_size = size.contain(fit_size) unless options[:upscale]
      fit_size
    end

    private

    def crop_gravity
      if uncropped? && !record.crop_gravity?
        size / 2
      else
        record.crop_gravity
      end
    end

    def crop_start
      if uncropped?
        Vector2d.new(0, 0)
      else
        record.crop_start
      end
    end

    def size
      if uncropped?
        record.real_size
      else
        record.size
      end
    end

    # Clamps the rectangle defined by +start+ and +size+
    # to fit inside 0, 0 and +max_size+. It is assumed
    # that +size+ will always be smaller than +max_size+.
    #
    # Returns the start vector.
    def clamp(start, size, max_size)
      start += shift_vector(start)
      start -= shift_vector(max_size - (start + size))
      start
    end

    def parse_vector(v)
      v.kind_of?(String) ? str_to_vector(v) : v
    end

    def record
      @record
    end

    def require_dimensions!(v)
      raise DynamicImage::Errors::InvalidSizeOptions unless v.x > 0 && v.y > 0
    end

    def shift_vector(vect)
      vector(
        vect.x < 0 ? vect.x.abs : 0,
        vect.y < 0 ? vect.y.abs : 0
      )
    end

    def str_to_vector(str)
      x, y = str.match(/(\d*)x(\d*)/)[1,2].map(&:to_i)
      Vector2d.new(x, y)
    end

    def uncropped?
      @uncropped
    end

    def vector(x, y)
      Vector2d.new(x, y)
    end
  end
end