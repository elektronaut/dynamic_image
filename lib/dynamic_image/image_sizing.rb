# encoding: utf-8

module DynamicImage
  class ImageSizing
    def initialize(record)
      @record = record
    end

    def crop_geometry(size)
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

    def crop_geometry_string(size)
      crop_size, start = crop_geometry(size)
      crop_size.floor.to_s + "+#{start.x.to_i}+#{start.y.to_i}"
    end

    private

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