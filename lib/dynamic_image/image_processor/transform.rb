# frozen_string_literal: true

module DynamicImage
  class ImageProcessor
    module Transform
      # Crops the image
      def crop(crop_size, crop_start)
        return self if crop_start == Vector2d(0, 0) && crop_size == size

        unless valid_crop?(crop_start, crop_size)
          raise DynamicImage::Errors::InvalidTransformation,
                "crop size is out of bounds"
        end

        each_frame do |frame|
          frame.crop(crop_start.x, crop_start.y, crop_size.x, crop_size.y)
        end
      end

      # Resize the image to a new size.
      def resize(new_size)
        new_size = Vector2d(new_size)
        apply image.thumbnail_image(new_size.x.to_i,
                                    height: new_size.y.to_i,
                                    crop: :none,
                                    size: :both)
      end

      # Rotates the image. The rotation must be a multiple of 90 degrees.
      def rotate(degrees)
        degrees = degrees.to_i % 360
        return self if degrees.zero?

        if (degrees % 90).nonzero?
          raise DynamicImage::Errors::InvalidTransformation,
                "angle must be a multiple of 90 degrees"
        end

        each_frame { |frame| frame.rotate(degrees) }
      end

      private

      def valid_crop?(crop_start, crop_size)
        bounds = crop_start + crop_size
        bounds.x <= size.x && bounds.y <= size.y
      end
    end
  end
end
