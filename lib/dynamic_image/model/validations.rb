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
        validate :validate_crop_bounds, if: :needs_crop_bounds_validation?
      end

      private

      def crop_out_of_bounds?
        crop = vector(crop_size) + vector(crop_start)
        max = vector(real_size)
        crop.x > max.x || crop.y > max.y
      end

      def needs_crop_bounds_validation?
        real_size? && crop_size?
      end

      def validate_crop_bounds
        if crop_out_of_bounds?
          self.errors.add(:crop_size, "is out of bounds")
        end
      end
    end
  end
end