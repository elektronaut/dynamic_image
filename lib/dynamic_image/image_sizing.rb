# encoding: utf-8

module DynamicImage
  class ImageSizing
    def initialize(record)
      @record = record
    end

    # Calculates crop geometry. The given vector is scaled
    # to match the image size, since DynamicImage performs
    # cropping before resizing.
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
      crop_size = ratio_vector.fit(record.size).round

      # Ignore pixels outside the pre-cropped area for now
      center = record.crop_gravity - record.crop_start

      start = center - (crop_size / 2).floor
      start = clamp(start, crop_size, record.size)

      [crop_size, (start + record.crop_start)]
    end

    # Returns crop geometry as an ImageMagick compatible string.
    #
    #   image = Image.find(params[:id]) # 320x200 image
    #   sizing = DynamicImage::ImageSizing.new(image)
    #
    #   sizing.crop_geometry(Vector2d(100, 100)) # => "200x200+60+0"
    def crop_geometry_string(ratio_vector)
      crop_size, start = crop_geometry(ratio_vector)
      crop_size.floor.to_s + "+#{start.x.to_i}+#{start.y.to_i}"
    end

    private

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

    def record
      @record
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