# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Image Sizing
  #
  # Calculates cropping and fitting for image sizes. The helpers use it to work out the dimensions of a rendered
  # image, and it can be used on its own when you need the size without rendering anything: reserving space in a
  # layout, filling in <tt>og:image:width</tt>, or laying out a PDF.
  #
  # The size it returns is the size that gets rendered. The helper floors it into the URL and the markup, and
  # {DynamicImage::ImageProcessor::Transform#resize_exact} honors that number instead of fitting it again. Scaling
  # is done in floating point, so +snap+ pulls an axis that lands a rounding error below a whole pixel back onto it
  # before the helper's floor can drop the pixel.
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
    # @raise [DynamicImage::Errors::InvalidSizeOptions] if the vector is zero on both axes
    #
    # @example
    #   image = Image.find(params[:id]) # 320x200 image
    #   sizing = DynamicImage::ImageSizing.new(image)
    #
    #   sizing.crop_geometry(Vector2d(100, 100))
    #   # => [Vector2d(200, 200), Vector2d(60, 0)]
    def crop_geometry(ratio_vector)
      require_nonzero!(ratio_vector)

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

      crop_geometry(Vector2d.new(ratio, 1)).first.x.floor
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
    # @raise [DynamicImage::Errors::InvalidSizeOptions] if <tt>crop: true</tt> is given and either dimension is zero,
    #   if the size is zero on both axes, or if the result is less than a pixel in either dimension
    #
    # @example
    #   image = Image.find(params[:id]) # 320x200 image
    #   sizing = DynamicImage::ImageSizing.new(image)
    #
    #   sizing.fit(Vector2d(0, 100))
    #   # => Vector2d(160.0, 100.0)
    #
    #   sizing.fit(Vector2d(500, 500))
    #   # => Vector2d(320, 200)
    #
    #   sizing.fit(Vector2d(500, 500), crop: true)
    #   # => Vector2d(200.0, 200.0)
    #
    #   sizing.fit(Vector2d(500, 500), upscale: true)
    #   # => Vector2d(500.0, 312.5)
    def fit(fit_size, options = {})
      fit_size = parse_vector(fit_size)
      require_dimensions!(fit_size) if options[:crop]
      require_nonzero!(fit_size)
      fit_size = snap(scale(fit_size, options))
      require_pixels!(fit_size)
      fit_size
    end

    # Fits the size like {#fit}, but returns the smallest size the image can be rendered at rather than raising when
    # the result lands under a pixel.
    #
    # @param fit_size [Vector2d, String] the size to fit within, as taken by {#fit}
    # @param options [Hash] as taken by {#fit}
    # @return [Vector2d] the resulting size
    # @raise [DynamicImage::Errors::InvalidSizeOptions] if the size is zero on both axes, or if <tt>crop: true</tt>
    #   is given and the crop is less than a pixel
    #
    # @example
    #   image = Image.find(params[:id]) # 2000x1 image
    #   sizing = DynamicImage::ImageSizing.new(image)
    #
    #   sizing.fit_renderable("1200x") # => Vector2d(2000.0, 1.0)
    def fit_renderable(fit_size, options = {})
      require_nonzero!(parse_vector(fit_size))
      return fit(fit_size, options) if options[:crop] || renderable?(fit_size, options)

      size.cover(1).round
    end

    # Returns true if the image can be rendered at +fit_size+, false if {#fit} rejects it.
    #
    # @param fit_size [Vector2d, String] the size to fit within, as taken by {#fit}
    # @param options [Hash] as taken by {#fit}
    # @return [Boolean]
    #
    # @example
    #   image = Image.find(params[:id]) # 320x200 image
    #   sizing = DynamicImage::ImageSizing.new(image)
    #
    #   sizing.renderable?(Vector2d(100, 0)) # => true
    #   sizing.renderable?(Vector2d(1, 0))   # => false
    def renderable?(fit_size, options = {})
      vector = parse_vector(fit_size)
      return false if options[:crop] && !(vector.x.positive? && vector.y.positive?)
      return false if vector.x.zero? && vector.y.zero?

      pixels?(snap(scale(vector, options)))
    end

    private

    def crop_gravity
      uncropped? && !record.crop_gravity? ? size / 2 : record.crop_gravity
    end

    def crop_start
      uncropped? ? Vector2d.new(0, 0) : record.crop_start
    end

    def size
      uncropped? ? record.real_size : record.size
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

    # Scales +fit_size+ against the image, honouring <tt>:crop</tt> and <tt>:upscale</tt>.
    def scale(fit_size, options)
      upscale = options[:upscale] ? true : false
      return size.fit(fit_size, upscale:) unless options[:crop]

      upscale ? fit_size : fit_size.fit(size, upscale: false)
    end

    def parse_vector(vector)
      vector.is_a?(String) ? str_to_vector(vector) : vector
    end

    attr_reader :record

    def require_dimensions!(vector)
      return if vector.x.positive? && vector.y.positive?

      raise DynamicImage::Errors::InvalidSizeOptions,
            "both dimensions are required when cropping"
    end

    # Rejects a vector that is zero on both axes. A single zero axis means the axis is unconstrained, but a vector
    # that is zero throughout constrains nothing and describes no image.
    def require_nonzero!(vector)
      return unless vector.x.zero? && vector.y.zero?

      raise DynamicImage::Errors::InvalidSizeOptions, "#{vector} has no size"
    end

    # Rejects sizes that don't round to at least one pixel in each dimension, since there is no image to render at
    # that point.
    def require_pixels!(vector)
      return if pixels?(vector)

      raise DynamicImage::Errors::InvalidSizeOptions,
            "#{vector} has a dimension smaller than one pixel"
    end

    def pixels?(vector)
      vector.x >= 1 && vector.y >= 1
    end

    def shift_vector(vect)
      Vector2d.new(
        vect.x.negative? ? vect.x.abs : 0,
        vect.y.negative? ? vect.y.abs : 0
      )
    end

    # Snaps each axis of +scaled+ onto the whole pixel it is a rounding error away from. Scaling is done in floating
    # point, so an axis that should land exactly on a pixel can come out a few ulps below it, and callers flooring
    # the result would lose that pixel.
    def snap(scaled)
      Vector2d.new(snap_axis(scaled.x), snap_axis(scaled.y))
    end

    def snap_axis(value)
      return value unless value.is_a?(Float) && value.finite?

      rounded = value.round
      (value - rounded).abs <= value.abs * 8 * Float::EPSILON ? rounded.to_f : value
    end

    def str_to_vector(str)
      x, y = str.match(/(\d*)x(\d*)/)[1, 2].map(&:to_i)
      Vector2d.new(x, y)
    end

    def uncropped?
      @uncropped
    end
  end
end
