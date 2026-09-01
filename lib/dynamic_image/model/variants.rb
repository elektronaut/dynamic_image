# frozen_string_literal: true

module DynamicImage
  module Model
    # = DynamicImage Model Variants
    #
    # Associates the image with its cached renderings.
    #
    # Each processed size is stored as a {DynamicImage::Variant}, so cropping and resizing is done once. Variants
    # are destroyed with the image, and cleared whenever its data changes.
    #
    # @see DynamicImage::ProcessedImage
    module Variants
      extend ActiveSupport::Concern

      included do
        has_many :variants,
                 as: :image,
                 class_name: "DynamicImage::Variant",
                 dependent: :destroy

        before_update :clear_variants, if: :data_changed?
      end

      private

      def clear_variants
        variants.destroy_all
      end
    end
  end
end
