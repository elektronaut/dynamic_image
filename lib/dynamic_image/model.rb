# encoding: utf-8

require "dynamic_image/model/dimensions"
require "dynamic_image/model/transformations"
require "dynamic_image/model/validations"

module DynamicImage
  # = DynamicImage Model
  #
  # ActiveModel extension for the model holding image data. It assumes your
  # database table has at least the following attributes:
  #
  #   create_table :images do |t|
  #     t.string  :content_hash
  #     t.string  :content_type
  #     t.integer :content_length
  #     t.string  :filename
  #     t.string  :colorspace
  #     t.integer :real_width, :real_height
  #     t.integer :crop_width, :crop_height
  #     t.integer :crop_start_x, :crop_start_y
  #     t.integer :crop_gravity_x, :crop_gravity_y
  #     t.timestamps
  #   end
  #
  # To use it, simply include it in your model:
  #
  #   class Image < ActiveRecord::Base
  #     include DynamicImage::Model
  #   end
  #
  # == Usage
  #
  # To save an image, simply assign to the +file+ attribute.
  #
  #   image = Image.create(file: params.permit(:file))
  #
  # This will automatically parse and validate the image when your record is
  # saved.
  #
  # To read back the image data, access the +data+ attribute. This will lazily
  # load the data from the store.
  #
  #   data = image.data
  #
  # == Cropping
  #
  # Images can be pre-cropped by setting +crop_width+, +crop_height+,
  # +crop_start_x+ and +crop_start_y+. The crop dimensions cannot exceed the
  # image size.
  #
  #   image.update(
  #     crop_start_x: 15, crop_start_y: 20,
  #     crop_width: 300, crop_height: 200
  #   )
  #   image.size # => Vector2d(300, 200)
  #
  # By default, images will be cropped from the center. You can control this
  # by setting +crop_gravity_x+ and +crop_gravity_y+. DynamicImage will make
  # sure the pixel referred to by these coordinates are present in the cropped
  # image, and as close to the center as possible without zooming in.
  module Model
    extend ActiveSupport::Concern
    include Dis::Model
    include DynamicImage::Model::Dimensions
    include DynamicImage::Model::Transformations
    include DynamicImage::Model::Validations

    included do
      before_validation :read_image_metadata, if: :data_changed?
    end

    # Returns true if the image is in the CMYK colorspace
    def cmyk?
      colorspace == "cmyk"
    end

    # Returns true if the image is in the grayscale colorspace
    def gray?
      colorspace == "gray"
    end

    # Returns true if the image is in the RGB colorspace
    def rgb?
      colorspace == "rgb"
    end

    # Finds a web safe content type. GIF, JPEG and PNG images are allowed,
    # any other formats should be converted to JPEG.
    def safe_content_type
      if safe_content_types.include?(content_type)
        content_type
      else
        "image/jpeg"
      end
    end

    # Includes a timestamp fingerprint in the URL param, so
    # that rendered images can be cached indefinitely.
    def to_param
      [id, updated_at.utc.to_s(cache_timestamp_format)].join("-")
    end

    private

    def read_image_metadata
      metadata = DynamicImage::Metadata.new(data)
      @valid_image = false
      if metadata.valid?
        self.colorspace = metadata.colorspace
        self.real_width = metadata.width
        self.real_height = metadata.height
        self.content_type = metadata.content_type
        @valid_image = true
      end
      true
    end

    def valid_image?
      @valid_image ? true : false
    end

    def safe_content_types
      %w(
        image/png
        image/gif
        image/jpeg
      )
    end
  end
end
