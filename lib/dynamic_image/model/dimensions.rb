# encoding: utf-8

module DynamicImage
  module Model
    module Dimensions
      def cropped?
        real_size? && (crop_size? && vector(real_size) != vector(crop_size))
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

      def valid_vector_string?(str)
        (str && str =~ /^\d+x\d+$/) ? true : false
      end

      def vector(str)
        if valid_vector_string?(str)
          Vector2d.parse(str)
        end
      end
    end
  end
end