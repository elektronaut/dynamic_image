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
  end
end