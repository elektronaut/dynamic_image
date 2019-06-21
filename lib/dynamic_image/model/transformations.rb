# frozen_string_literal: true

module DynamicImage
  module Model
    # = DynamicImage Model Transformations
    #
    module Transformations
      # Resizes the image
      def resize(max_size)
        transform_image do |image|
          new_size = real_size.constrain_both(max_size)
          scale = new_size.x / real_size.x
          image.resize(new_size)
          crop_attributes.each do |attr|
            self[attr] = self[attr] * scale if self[attr]
          end
        end
      end

      # Rotates the image
      def rotate(degrees = 90)
        degrees = degrees.to_i % 360

        return self if degrees.zero?

        if (degrees % 90).nonzero?
          raise DynamicImage::Errors::InvalidTransformation,
                "angle must be a multiple of 90 degrees"
        end

        transform_image do |image|
          image.rotate(degrees)
          rotate_dimensions(real_size.x, real_size.y, degrees)
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

      def processed_image
        DynamicImage::ProcessedImage.new(self, uncropped: true)
      end

      def transform_image
        read_image_metadata if data_changed?
        self.data = processed_image.normalized do |image|
          yield(image) if block_given?
        end
        read_image_metadata
        self
      end
    end
  end
end
