# encoding: utf-8

require 'dynamic_image/model/dimensions'
require 'dynamic_image/model/validations'

module DynamicImage
  module Model
    extend ActiveSupport::Concern
    include Shrouded::Model
    include DynamicImage::Model::Dimensions
    include DynamicImage::Model::Validations

    included do
      before_validation :read_image_metadata, if: :data_changed?
    end

    def cmyk?
      colorspace == "cmyk"
    end

    def gray?
      colorspace == "gray"
    end

    def rgb?
      colorspace == "rgb"
    end

    def safe_content_type
      if safe_content_types.include?(content_type)
        content_type
      else
        'image/jpeg'
      end
    end

    def to_param
      [id, updated_at.utc.to_s(cache_timestamp_format)].join('-')
    end

    private

    def read_image_metadata
      metadata = DynamicImage::Metadata.new(self.data)
      if metadata.valid?
        self.colorspace = metadata.colorspace
        self.real_width = metadata.width
        self.real_height = metadata.height
        self.content_type = metadata.content_type
        @valid_image = true
      else
        @valid_image = false
      end
      true
    end

    def valid_image?
      @valid_image ? true : false
    end

    def safe_content_types
      %w{
        image/png
        image/gif
        image/jpeg
      }
    end
  end
end