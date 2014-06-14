# encoding: utf-8

module DynamicImage
  module Model
    module Validations
      extend ActiveSupport::Concern
      included do
        validates :data,
          presence: true
        validates :content_type,
          presence: true,
          format: /\Aimage\/(gif|jpeg|pjpeg|png)\z/
        validates :content_length,
          presence: true,
          numericality: { greater_than: 0 }
        validates :filename,
          presence: true,
          length: { maximum: 255 }
        validates :real_size, :crop_size, :crop_start,
          presence: true,
          format: /\A\d+x\d+\z/
        validate :validate_crop_bounds, if: :cropped?
      end

      private

      def crop_out_of_bounds?
        crop = vector(crop_size)
        crop += vector(crop_start) if crop_start?
        max = vector(real_size)
        crop.x > max.x || crop.y > max.y
      end

      def validate_crop_bounds
        if crop_out_of_bounds?
          self.errors.add(:crop_size, "is out of bounds")
        end
      end
    end
  end
end