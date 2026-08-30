# frozen_string_literal: true

require "dis"
require "vector2d"
require "vips"

require "dynamic_image/backfill"
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
require "dynamic_image/metadata"
require "dynamic_image/model"
require "dynamic_image/processed_image"
require "dynamic_image/routing"
require "dynamic_image/schema"

# DynamicImage handles image uploads in Rails. Rather than building a
# fixed set of derivatives when a file is uploaded, it stores the
# original and generates cropped, resized and format-converted versions
# on demand, caching each one as a variant.
#
# Include {DynamicImage::Model} in the model holding the image and
# {DynamicImage::Controller} in the controller serving it, then declare
# the routes with {DynamicImage::Routing#image_resources}. Views render
# images through the helpers in {DynamicImage::Helper}, which sign the
# URLs.
#
# Files are stored with Dis, and processing is done with libvips.
#
# @see DynamicImage::Model
# @see DynamicImage::Controller
# @see DynamicImage::Helper
# @see DynamicImage::ImageSizing
# @see DynamicImage::ProcessedImage
module DynamicImage
  # Verifies the HMAC digests embedded in image URLs. Set by the engine
  # from the application's key generator, which derives it from
  # <tt>secret_key_base</tt>.
  #
  # @return [DynamicImage::DigestVerifier] the verifier
  cattr_accessor :digest_verifier
end
