# encoding: utf-8

module DynamicImage
  module Model
    module Validations
      extend ActiveSupport::Concern
      included do
        validates :content_type,
          presence: true,
          format: /\Aimage\/(gif|jpeg|pjpeg|png)\z/

        validates :content_length,
          presence: true,
          numericality: { greater_than: 0, only_integer: true }

        validates :data,
          presence: true

        validates :filename,
          presence: true,
          length: { maximum: 255 }

        validates :real_width, :real_height,
          numericality: { greater_than: 0, only_integer: true }

        validates :crop_width, :crop_height, :crop_start_x,
          :crop_start_y, :crop_gravity_x, :crop_gravity_y,
          numericality: { greater_than: 0, only_integer: true },
          allow_nil: true

        validates :real_width, :real_height,
          presence: true

        validates :crop_width, presence: true, if: :crop_height?
        validates :crop_height, presence: true, if: :crop_width?

        validates :crop_start_x, presence: true, if: :crop_start_y?
        validates :crop_start_y, presence: true, if: :crop_start_x?

        validates :crop_gravity_x, presence: true, if: :crop_gravity_y?
        validates :crop_gravity_y, presence: true, if: :crop_gravity_x?

        validate :validate_crop_bounds, if: :cropped?
      end

      private

      def validate_crop_bounds
        required_size = crop_start + crop_size
        if required_size.x > real_size.x || required_size.y > real_size.y
          self.errors.add(:crop_size, "is out of bounds")
        end
      end
    end
  end
end