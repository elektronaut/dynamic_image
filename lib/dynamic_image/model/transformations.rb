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
          new_size = real_size.constrain_both(max_size)
          scale = new_size.x / real_size.x
          crop_attributes.each do |attr|
            self[attr] = self[attr] * scale if self[attr]
          end
          image.resize(new_size)
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

      def crop_attributes
        %i[crop_width crop_height crop_start_x crop_start_y
           crop_gravity_x crop_gravity_y]
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
