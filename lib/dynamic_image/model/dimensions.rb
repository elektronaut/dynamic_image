# encoding: utf-8

module DynamicImage
  module Model
    module Dimensions
      def cropped?
        (crop_start? && vector(crop_start) != null_vector) ||
        (crop_size? && vector(real_size) != vector(crop_size))
      end

      def size
        crop_size || real_size
      end

      def width
        vector(size).try(:x)
      end

      def height
        vector(size).try(:y)
      end

      private

      def null_vector
        Vector2d.new(0, 0)
      end

      def vector(str)
        return nil unless str =~ /^\d+x\d+$/
        Vector2d.parse(str)
      end
    end
  end
end