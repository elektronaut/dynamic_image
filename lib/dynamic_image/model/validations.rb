# frozen_string_literal: true

module DynamicImage
  module Model
    # = DynamicImage Model Validations
    #
    # Validates that all necessary attributes are valid. All of these are
    # managed by +DynamicImage::Model+, so this is mostly for enforcing
    # integrity.
    #
    # The two that can fail on ordinary input are the image itself,
    # which is rejected if the data isn't readable in a supported
    # format, and the crop, which has to fit within the image.
    module Validations
      extend ActiveSupport::Concern

      included do
        validates_data_presence

        validates :colorspace,
                  presence: true,
                  inclusion: { in: allowed_colorspaces }

        validates :content_type,
                  presence: true,
                  inclusion: { in: allowed_content_types }

        validates :content_length,
                  presence: true,
                  numericality: { greater_than: 0, only_integer: true }

        validates :filename,
                  presence: true,
                  length: { maximum: 255 }

        validates :real_width, :real_height,
                  presence: true,
                  numericality: { greater_than: 0, only_integer: true }

        validates :crop_width, :crop_height,
                  :crop_gravity_x, :crop_gravity_y,
                  numericality: { greater_than: 0, only_integer: true },
                  allow_nil: true

        validates :crop_width, presence: true, if: :crop_height?
        validates :crop_height, presence: true, if: :crop_width?

        validates :crop_start_x, presence: true, if: :crop_start_y?
        validates :crop_start_y, presence: true, if: :crop_start_x?

        validates :crop_gravity_x, presence: true, if: :crop_gravity_y?
        validates :crop_gravity_y, presence: true, if: :crop_gravity_x?

        validate :validate_crop_bounds, if: :cropped?
        validate :validate_image, if: :data_changed?
      end

      module ClassMethods
        # Colorspaces an image is allowed to be in.
        #
        # @return [Array<String>] the colorspace names
        def allowed_colorspaces
          %w[rgb cmyk gray]
        end

        # Content types an image is allowed to have, taken from the
        # registered formats.
        #
        # @return [Array<String>] the content types
        def allowed_content_types
          DynamicImage::Format.content_types
        end
      end

      private

      def validate_crop_bounds
        required_size = crop_start + crop_size
        return unless required_size.x > real_size.x ||
                      required_size.y > real_size.y

        errors.add(:crop_size, "is out of bounds")
      end

      def validate_image
        errors.add(:data, :invalid) unless valid_image?
      end
    end
  end
end
