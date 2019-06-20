# frozen_string_literal: true

module DynamicImage
  class Variant < ActiveRecord::Base
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
