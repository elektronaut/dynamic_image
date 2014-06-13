# encoding: utf-8

module DynamicImage
  module Model
    module Dimensions
      def cropped?
        (crop_start? && vector(crop_start) != vector(0, 0)) ||
        (crop_size? && vector(real_size) != vector(crop_size))
      end

      def size
        crop_size || real_size
      end

      def width
        vector(size).x
      end

      def height
        vector(size).y
      end

      private

      def vector(*args)
        Vector2d.parse(*args)
      end
    end
  end
end