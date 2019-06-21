# frozen_string_literal: true

module DynamicImage
  module Model
    # = DynamicImage Model Dimensions
    #
    module Dimensions
      # Returns the crop gravity.
      #
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

      # Returns true if crop gravity has been explicitely set.
      def crop_gravity?
        crop_gravity_x.present? && crop_gravity_y.present?
      end

      # Returns the crop size, or nil if no cropping is applied.
      def crop_size
        vector(crop_width, crop_height) if crop_size?
      end

      # Returns true if crop size has been set.
      def crop_size?
        crop_width? && crop_height?
      end

      # Returns the crop start if set, or Vector2d(0, 0) if not.
      def crop_start
        if crop_start?
          vector(crop_start_x, crop_start_y)
        else
          vector(0, 0)
        end
      end

      # Returns true if crop start has been set.
      def crop_start?
        crop_start_x.present? && crop_start_y.present?
      end

      # Returns true if the image is cropped.
      def cropped?
        crop_size? && real_size? && crop_size != real_size
      end

      # Returns the real size of the image, without any cropping applied.
      def real_size
        vector(real_width, real_height) if real_size?
      end

      # Returns true if the size has been set.
      def real_size?
        real_width? && real_height?
      end

      # Returns the cropped size if the image has been cropped. If not,
      # it returns the actual size.
      def size
        crop_size || real_size
      end

      # Returns true if the image has size set.
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
