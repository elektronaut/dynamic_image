# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Variant
  #
  # A cached rendering of an image at one particular size, crop and
  # format. Variants are created on demand by
  # {DynamicImage::ProcessedImage} and destroyed when the image they
  # belong to changes or is destroyed, so there is rarely a reason to
  # work with them directly.
  #
  # Data is stored in Dis under its own type, keeping it separate from
  # the originals.
  #
  # @see DynamicImage::ProcessedImage
  # @see DynamicImage::Model::Variants
  class Variant < ApplicationRecord
    include Dis::Model

    self.table_name = "dynamic_image_variants"
    self.dis_type = "image-variants"

    belongs_to :image, polymorphic: true, inverse_of: :variants

    validates_data_presence

    validates :format, presence: true

    validates :width, :height, :crop_width, :crop_height,
              numericality: { greater_than: 0, only_integer: true }

    validates :crop_start_x, :crop_start_y,
              numericality: { only_integer: true }
  end
end
