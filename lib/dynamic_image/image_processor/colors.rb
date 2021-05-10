# frozen_string_literal: true

module DynamicImage
  class ImageProcessor
    # = ImageProcessor::Colors
    #
    # Performs the necessary profile conversions on the image. All
    # images are converted to the sRGB colorspace using either the
    # embedded profile, or the built-in generic profile. Grayscale
    # images are converted back to grayscale after processing.
    module Colors
      private

      def icc_profile?(image)
        image.get_fields.include?("icc-profile-data")
      end

      def icc_transform_srgb(image)
        return image unless icc_profile?(image)

        image.icc_transform("srgb", embedded: true, intent: :perceptual)
      end

      def screen_profile(image)
        if !icc_profile?(image) && %i[rgb b-w].include?(image.interpretation)
          return image
        end

        target_space = image.interpretation == :"b-w" ? "b-w" : "srgb"
        icc_transform_srgb(image).colourspace(target_space)
      end
    end
  end
end
