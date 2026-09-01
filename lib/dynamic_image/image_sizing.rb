# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Image Sizing
  #
  # Calculates cropping and fitting for image sizes. The helpers use it to work out the dimensions of a rendered
  # image, and it can be used on its own when you need the size without rendering anything: reserving space in a
  # layout, filling in <tt>og:image:width</tt>, or laying out a PDF.
  #
  # @example
  #   sizing = DynamicImage::ImageSizing.new(image)
  #   sizing.fit("400x400") # => Vector2d(400.0, 250.0)
  class ImageSizing
    # @param record [DynamicImage::Model] the image
    # @param options [Hash]
    # @option options [Boolean] :uncropped Ignore any crop stored on the record and size against the original image
    def initialize(record, options = {})
      @record = record
      @uncropped = options[:uncropped] ? true : false
    end

    # Calculates crop geometry. The given vector is scaled to match the image size, since cropping happens before
    # resizing.
    #
    # The crop is positioned to keep the record's crop gravity as close to the center as possible, clamped to the
    # bounds of the image.
    #
    # @param ratio_vector [Vector2d] the aspect ratio to crop to
    # @return [Array(Vector2d, Vector2d)] the crop size and crop start
    #
    # @example
    #   image = Image.find(params[:id]) # 320x200 image
    #   sizing = DynamicImage::ImageSizing.new(image)
    #
    #   sizing.crop_geometry(Vector2d(100, 100))
    #   # => [Vector2d(200, 200), Vector2d(60, 0)]
    def crop_geometry(ratio_vector)
      # Maximize the crop area to fit the image size
      crop_size = ratio_vector.fit(size).round

      # Ignore pixels outside the pre-cropped area for now
      center = crop_gravity - crop_start

      start = center - (crop_size / 2).floor
      start = clamp(start, crop_size, size)

      [crop_size, (start + crop_start)]
    end

    # Returns the widest the image can be rendered at, in pixels.
    #
    # Without a ratio this is the image's own width. With one it is the width of the largest crop matching that
    # ratio.
    #
    # @param ratio [Numeric, Vector2d, String, nil] the aspect ratio, in any form {DynamicImage::Ratio} understands
    # @return [Integer]
    #
    # @example
    #   image = Image.find(params[:id]) # 320x200 image
    #   sizing = DynamicImage::ImageSizing.new(image)
    #
    #   sizing.available_width           # => 320
    #   sizing.available_width(16.0 / 9) # => 320
    #   sizing.available_width(9.0 / 16) # => 113
    def available_width(ratio = nil)
      ratio = DynamicImage::Ratio.parse(ratio)
      return size.x.floor unless ratio

      crop_geometry(vector(ratio, 1)).first.x.floor
    end

    # Adjusts +fit_size+ to fit the image dimensions. Any dimension set to zero will be ignored.
    #
    # @param fit_size [Vector2d, String] the size to fit within, either a vector or a <tt>"{width}x{height}"</tt>
    #   string. Either dimension may be omitted for a fixed width or height.
    # @param options [Hash]
    # @option options [Boolean] :crop Don't keep aspect ratio. This will allow the image to be cropped to the
    #   requested size.
    # @option options [Boolean] :upscale Don't limit to the size of the image. Images smaller than the given size will
    #   be scaled up.
    # @return [Vector2d] the resulting size
    # @raise [DynamicImage::Errors::InvalidSizeOptions] if <tt>crop: true</tt> is given and either dimension is zero
    #
    # @example
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
    def fit(fit_size, options = {})
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

    # Clamps the rectangle defined by +start+ and +size+ to fit inside 0, 0 and +max_size+. It is assumed that +size+
    # will always be smaller than +max_size+.
    #
    # Returns the start vector.
    def clamp(start, size, max_size)
      start += shift_vector(start)
      start -= shift_vector(max_size - (start + size))
      start
    end

    def parse_vector(vector)
      vector.is_a?(String) ? str_to_vector(vector) : vector
    end

    attr_reader :record

    def require_dimensions!(vector)
      return if vector.x.positive? && vector.y.positive?

      raise DynamicImage::Errors::InvalidSizeOptions
    end

    def shift_vector(vect)
      vector(
        vect.x.negative? ? vect.x.abs : 0,
        vect.y.negative? ? vect.y.abs : 0
      )
    end

    def str_to_vector(str)
      x, y = str.match(/(\d*)x(\d*)/)[1, 2].map(&:to_i)
      Vector2d.new(x, y)
    end

    def uncropped?
      @uncropped
    end

    def vector(width, height)
      Vector2d.new(width, height)
    end
  end
end
