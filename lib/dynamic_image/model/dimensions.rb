# frozen_string_literal: true

module DynamicImage
  module Model
    # = DynamicImage Model Dimensions
    #
    # Vector accessors over the +real_*+ and +crop_*+ columns.
    #
    # +real_size+ is the size of the stored image. +size+ is the size
    # after cropping, falling back to +real_size+ if no crop is set.
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
      #
      # @return [Vector2d, nil] the crop gravity
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
      #
      # @return [Boolean]
      def crop_gravity?
        crop_gravity_x.present? && crop_gravity_y.present?
      end

      # Returns the crop size, or nil if no cropping is applied.
      #
      # @return [Vector2d, nil] the crop size
      def crop_size
        vector(crop_width, crop_height) if crop_size?
      end

      # Returns true if crop size has been set.
      #
      # @return [Boolean]
      def crop_size?
        crop_width? && crop_height?
      end

      # Returns the crop start if set, or Vector2d(0, 0) if not.
      #
      # @return [Vector2d] the top left corner of the crop
      def crop_start
        if crop_start?
          vector(crop_start_x, crop_start_y)
        else
          vector(0, 0)
        end
      end

      # Returns true if crop start has been set.
      #
      # @return [Boolean]
      def crop_start?
        crop_start_x.present? && crop_start_y.present?
      end

      # Returns true if the image is cropped.
      #
      # @return [Boolean]
      def cropped?
        crop_size? && real_size? && crop_size != real_size
      end

      # Returns the real size of the image, without any cropping applied.
      #
      # @return [Vector2d, nil] the size of the stored image
      def real_size
        vector(real_width, real_height) if real_size?
      end

      # Returns true if the size has been set.
      #
      # @return [Boolean]
      def real_size?
        real_width? && real_height?
      end

      # Returns the cropped size if the image has been cropped. If not,
      # it returns the actual size.
      #
      # @return [Vector2d, nil] the visible size of the image
      def size
        crop_size || real_size
      end

      # Returns true if the image has size set.
      #
      # @return [Boolean]
      def size?
        size ? true : false
      end

      private

      def vector(width, height)
        Vector2d.new(width, height)
      end
    end
  end
end
