# frozen_string_literal: true

module DynamicImage
  module Jobs
    # = Create variant
    #
    # Creates an image variant.
    class CreateVariant < ActiveJob::Base
      queue_as :dis

      def perform(record, options, size)
        size_v = Vector2d.parse(size)
        DynamicImage::ProcessedImage.new(record, options)
                                    .find_or_create_variant(size_v)
      end
    end
  end
end
