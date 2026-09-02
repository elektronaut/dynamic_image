# frozen_string_literal: true

require "dynamic_image/model/dimensions"
require "dynamic_image/model/transformations"
require "dynamic_image/model/validations"
require "dynamic_image/model/variants"

module DynamicImage
  # = DynamicImage Model
  #
  # ActiveModel extension for the model holding image data. The table needs at least the attributes in
  # {DynamicImage::Schema::ATTRIBUTES}:
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
  # Include it in your model:
  #
  #   class Image < ActiveRecord::Base
  #     include DynamicImage::Model
  #   end
  #
  # == Usage
  #
  # To save an image, assign to the +file+ attribute. The image is parsed and validated when the record is saved.
  #
  #   image = Image.create(file: params.permit(:file))
  #
  # To read back the image data, access the +data+ attribute. The data is loaded lazily from the store.
  #
  #   data = image.data
  #
  # == Cropping
  #
  # Images can be pre-cropped by setting +crop_width+, +crop_height+, +crop_start_x+ and +crop_start_y+. The crop
  # dimensions cannot exceed the image size.
  #
  #   image.update(
  #     crop_start_x: 15, crop_start_y: 20,
  #     crop_width: 300, crop_height: 200
  #   )
  #   image.size # => Vector2d(300, 200)
  #
  # By default, images will be cropped from the center. You can control this by setting +crop_gravity_x+ and
  # +crop_gravity_y+. DynamicImage will make sure the pixel referred to by these coordinates are present in the
  # cropped image, and as close to the center as possible without zooming in.
  #
  # @see DynamicImage::Model::Dimensions
  # @see DynamicImage::Model::Transformations
  # @see DynamicImage::Model::Validations
  # @see DynamicImage::Model::Variants
  module Model
    extend ActiveSupport::Concern
    include Dis::Model
    include DynamicImage::Model::Dimensions
    include DynamicImage::Model::Transformations
    include DynamicImage::Model::Validations
    include DynamicImage::Model::Variants

    included do
      before_validation :read_image_metadata, if: :data_changed?
    end

    # Returns true if the image holds more than one frame.
    #
    # Images stored before +frame_count+ existed have none, and are taken to be still.
    #
    # @return [Boolean]
    def animated?
      has_attribute?(:frame_count) && frame_count.to_i > 1
    end

    # Returns the alt text for the image, or nil if none has been set.
    #
    # DynamicImage doesn't add this column by default. Either create it yourself or override the method to
    # provide your own implementation.
    #
    # Note that there is a distinction between nil and a blank string. <tt>alt=""</tt> means the image is
    # purely decorative, while a missing attribute is an accessibility defect.
    #
    # @return [String, nil]
    # @see DynamicImage::Helper#dynamic_image_tag
    def alt_text
      self[:alt_text] if has_attribute?(:alt_text)
    end

    # Returns true if the image is in the CMYK colorspace.
    #
    # @return [Boolean]
    def cmyk?
      colorspace == "cmyk"
    end

    # Returns true if the image is in the grayscale colorspace.
    #
    # @return [Boolean]
    def gray?
      colorspace == "gray"
    end

    # Returns true if the image is in the RGB colorspace.
    #
    # @return [Boolean]
    def rgb?
      colorspace == "rgb"
    end

    # Finds a web safe content type, negotiated against {DynamicImage.default_formats}.
    #
    # @return [String]
    # @see DynamicImage::FormatNegotiator
    def safe_content_type
      DynamicImage::FormatNegotiator
        .new(self).negotiate(DynamicImage.default_formats).content_type
    end

    # Includes a timestamp fingerprint in the URL param, so rendered images can be cached indefinitely.
    #
    # @return [String] the id and an +updated_at+ fingerprint
    def to_param
      [id, updated_at.utc.to_fs(cache_timestamp_format)].join("-")
    end

    private

    def read_image_metadata
      @valid_image = false
      with_data_file do |path|
        apply_image_metadata(DynamicImage::Metadata.new(path))
      end
    end

    def apply_image_metadata(metadata)
      return unless metadata.valid?

      self.colorspace = metadata.colorspace
      self.real_width = metadata.width
      self.real_height = metadata.height
      self.content_type = metadata.content_type
      self.frame_count = metadata.frame_count if has_attribute?(:frame_count)
      self.alpha = metadata.alpha? if has_attribute?(:alpha)
      @valid_image = true
    end

    def valid_image?
      @valid_image ? true : false
    end
  end
end
