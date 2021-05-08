# frozen_string_literal: true

require "dis"
require "vector2d"
require "vips"

require "dynamic_image/belongs_to"
require "dynamic_image/controller"
require "dynamic_image/digest_verifier"
require "dynamic_image/engine"
require "dynamic_image/errors"
require "dynamic_image/format"
require "dynamic_image/helper"
require "dynamic_image/image_processor"
require "dynamic_image/image_reader"
require "dynamic_image/image_sizing"
require "dynamic_image/jobs"
require "dynamic_image/metadata"
require "dynamic_image/model"
require "dynamic_image/processed_image"
require "dynamic_image/routing"

module DynamicImage
  cattr_accessor :digest_verifier, :process_later_limit
end
