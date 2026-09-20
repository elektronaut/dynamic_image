# frozen_string_literal: true

module DynamicImage
  class ImageProcessor
    # = ImageProcessor::Transform
    #
    # Cropping, resizing and rotation. Each operation is applied to every frame of an animated image.
    module Transform
      # Crops the image.
      #
      # @param crop_size [Vector2d] the size of the crop
      # @param crop_start [Vector2d] its top left corner
      # @return [DynamicImage::ImageProcessor] a new processor
      # @raise [DynamicImage::Errors::InvalidTransformation] if the crop falls outside the image
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

      # Resizes the image to fit within +new_size+, retaining its aspect ratio. Crop first if the image needs to
      # fill the size exactly.
      #
      # @param new_size [Vector2d] the size to fit within
      # @return [DynamicImage::ImageProcessor] a new processor
      def resize(new_size)
        new_size = size.fit(Vector2d(new_size)).round
        apply image.thumbnail_image(new_size.x,
                                    height: new_size.y,
                                    crop: :none,
                                    size: :force)
      end

      # Rotates the image. The rotation must be a multiple of 90 degrees.
      #
      # @param degrees [Integer] the angle
      # @return [DynamicImage::ImageProcessor] a new processor
      # @raise [DynamicImage::Errors::InvalidTransformation] if the angle isn't a multiple of 90
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
