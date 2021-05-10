# frozen_string_literal: true

module DynamicImage
  class ImageProcessor
    module Colors
      # Performs the necessary profile conversions on the image. All
      # images are converted to the sRGB colorspace using either the
      # embedded profile, or the built-in generic profile. Grayscale
      # images are converted back to grayscale after processing.
      def screen_profile
        if !icc_profile? && %i[rgb b-w].include?(image.interpretation)
          return self
        end

        target_space = image.interpretation == :"b-w" ? "b-w" : "srgb"
        apply icc_transform_srgb(image).colourspace(target_space)
      end

      private

      def icc_profile?
        image.get_fields.include?("icc-profile-data")
      end

      def icc_transform_srgb(image)
        return image unless icc_profile?

        image.icc_transform("srgb", embedded: true, intent: :perceptual)
      end
    end
  end
end
