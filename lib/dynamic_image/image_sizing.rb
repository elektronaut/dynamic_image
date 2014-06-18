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