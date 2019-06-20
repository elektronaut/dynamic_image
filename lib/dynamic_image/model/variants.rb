# frozen_string_literal: true

module DynamicImage
  module Model
    # = DynamicImage Model Variants
    #
    # Validates that all necessary attributes are valid. All of these are
    # managed by +DynamicImage::Model+, so this is mostly for enforcing
    # integrity.
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
