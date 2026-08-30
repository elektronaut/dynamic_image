# frozen_string_literal: true

module DynamicImage
  module Model
    # = DynamicImage Model Transformations
    #
    # Transformations that rewrite the stored file, as opposed to the
    # processing done per request, which never touches it.
    #
    # Both methods replace the data and update the stored dimensions,
    # adjusting the crop to match. Neither saves the record.
    module Transformations
      # Resizes the image, replacing the stored file with a smaller one.
      # The crop is scaled along with it.
      #
      # @param max_size [Vector2d] the size to scale down to
      # @return [self]
      def resize(max_size)
        transform_image do |image|
          resized = image.resize(real_size.constrain_both(max_size))
          scale_crop(resized.size)
          resized
        end
      end

      # Rotates the image, taking the crop and crop gravity with it.
      #
      # @param degrees [Integer] the angle, which must be a multiple of
      #   90. Rotating by 0 is a no-op.
      # @return [self]
      # @raise [DynamicImage::Errors::InvalidTransformation] if the
      #   angle isn't a multiple of 90
      #
      # @example
      #   image.rotate(90)
      #   image.save
      def rotate(degrees = 90)
        degrees = degrees.to_i % 360

        return self if degrees.zero?

        if (degrees % 90).nonzero?
          raise DynamicImage::Errors::InvalidTransformation,
                "angle must be a multiple of 90 degrees"
        end

        transform_image do |image|
          rotate_dimensions(real_size.x, real_size.y, degrees)
          image.rotate(degrees)
        end
      end

      private

      def scale_crop(new_size)
        scale = new_size.to_f_vector / real_size

        scale_crop_start(scale, new_size)
        scale_crop_size(scale, new_size)
        scale_crop_gravity(scale, new_size)
      end

      def scale_crop_start(scale, new_size)
        return unless crop_start?

        self.crop_start_x, self.crop_start_y =
          (crop_start * scale).floor.clamp(0, new_size - 1).to_a
      end

      def scale_crop_size(scale, new_size)
        return unless crop_size?

        self.crop_width, self.crop_height =
          (crop_size * scale).round.clamp(1, new_size - crop_start).to_a
      end

      def scale_crop_gravity(scale, new_size)
        return unless crop_gravity?

        self.crop_gravity_x, self.crop_gravity_y =
          (crop_gravity * scale).round.clamp(1, new_size).to_a
      end

      def rotate_dimensions(width, height, degrees)
        (degrees / 90).times do
          width, height = height, width

          self.real_width = width
          self.real_height = height

          self.crop_gravity_x, self.crop_gravity_y = rotated_crop_gravity(width)

          next unless cropped?

          self.crop_start_x, self.crop_start_y,
          self.crop_width, self.crop_height = rotated_crop(width)
        end
      end

      def rotated_crop(new_width)
        return nil unless cropped?

        [
          new_width - (crop_start_y + crop_height),
          crop_start_x,
          crop_height,
          crop_width
        ]
      end

      def rotated_crop_gravity(new_width)
        return nil unless crop_gravity?

        [new_width - crop_gravity_y, crop_gravity_x]
      end

      def transform_image(&block)
        read_image_metadata if data_changed?
        self.data = with_data_file do |path|
          block.call(DynamicImage::ImageProcessor.new(path)).read
        end
        read_image_metadata
        self
      end
    end
  end
end
