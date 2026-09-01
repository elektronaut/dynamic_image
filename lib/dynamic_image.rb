# frozen_string_literal: true

require "dis"
require "vector2d"
require "vips"

require "dynamic_image/backfill"
require "dynamic_image/belongs_to"
require "dynamic_image/breakpoints"
require "dynamic_image/controller"
require "dynamic_image/digest_verifier"
require "dynamic_image/engine"
require "dynamic_image/errors"
require "dynamic_image/format"
require "dynamic_image/format_negotiator"
require "dynamic_image/helper"
require "dynamic_image/image_processor"
require "dynamic_image/image_reader"
require "dynamic_image/image_sizing"
require "dynamic_image/metadata"
require "dynamic_image/model"
require "dynamic_image/picture"
require "dynamic_image/picture/format_policy"
require "dynamic_image/processed_image"
require "dynamic_image/ratio"
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
  # The formats anything that renders images will understand. Fallback images in a <tt>picture</tt> are negotiated
  # from this list, and it is the default for {DynamicImage.mailer_formats}.
  #
  # @return [Array<Symbol>] the format names, most preferred first
  COMPATIBLE_FORMATS = %i[jpeg png gif].freeze

  # Verifies the HMAC digests embedded in image URLs. Set by the engine
  # from the application's key generator, which derives it from
  # <tt>secret_key_base</tt>.
  #
  # @return [DynamicImage::DigestVerifier] the verifier
  cattr_accessor :digest_verifier

  # The formats a view accepts when it doesn't pass <tt>format:</tt>.
  # Also decides what {DynamicImage::Model#safe_content_type} considers
  # safe.
  #
  # @return [Array<Symbol>] the format names, most preferred first
  mattr_accessor :default_formats, default: %i[jpeg png gif webp]

  # The formats a mailer view accepts when it doesn't pass
  # <tt>format:</tt>.
  #
  # @return [Array<Symbol>] the format names, most preferred first
  mattr_accessor :mailer_formats, default: COMPATIBLE_FORMATS

  # The breakpoints responsive images are rendered at. This can
  # be a range, an array of explicit widths, or a single width.
  #
  # @return [Range, Array<Integer>, Integer] the breakpoints
  # @see DynamicImage::Breakpoints
  mattr_accessor :default_breakpoints, default: 320..3200

  # The ratio between two breakpoints. Lower means a closer fit to what the
  # browser needs, at the price of more variants to generate and store.
  #
  # @return [Float] the step
  mattr_accessor :breakpoint_step, default: 1.4

  # The width of the fallback image in a <tt>picture</tt> element.
  #
  # @return [Integer] the width
  mattr_accessor :picture_fallback_width, default: 1200
end
