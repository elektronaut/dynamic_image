# encoding: utf-8

module DynamicImage
  module Model
    module Dimensions

      # DynamicImage will try to keep the pixel represented by
      # crop_gravity as close to the center as possible when cropping
      # images.
      #
      # It is relative to 0,0 on the original image.
      #
      # Unless crop_gravity has been explicitely set, it defaults to
      # the center of the cropped image.
      def crop_gravity
        if crop_gravity?
          vector(crop_gravity_x, crop_gravity_y)
        elsif cropped?
          crop_start + (crop_size / 2)
        elsif size?
          size / 2
        end
      end

      def crop_gravity?
        crop_gravity_x.present? && crop_gravity_y.present?
      end

      def crop_size
        if crop_size?
          vector(crop_width, crop_height)
        end
      end

      def crop_size?
        crop_width? && crop_height?
      end

      def crop_start
        if crop_start?
          vector(crop_start_x, crop_start_y)
        else
          vector(0, 0)
        end
      end

      def crop_start?
        crop_start_x? && crop_start_y?
      end

      def cropped?
        crop_size? && real_size? && crop_size != real_size
      end

      def real_size
        if real_size?
          vector(real_width, real_height)
        end
      end

      def real_size?
        real_width? && real_height?
      end

      def size
        crop_size || real_size
      end

      def size?
        size ? true : false
      end

      private

      def vector(x, y)
        Vector2d.new(x, y)
      end
    end
  end
end