# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Errors
  #
  # All errors raised by DynamicImage inherit from
  # {DynamicImage::Errors::Error}, so a single rescue covers them all.
  module Errors
    # Base class for all DynamicImage errors.
    class Error < StandardError; end

    # Raised when processing is attempted on a record that isn't a valid
    # image, either because the data is unreadable or because the record
    # fails validation.
    #
    # @see DynamicImage::ProcessedImage#normalized
    class InvalidImage < DynamicImage::Errors::Error; end

    # Raised when reading data that isn't in a format DynamicImage
    # recognizes. The header is sniffed rather than trusting any
    # declared content type.
    #
    # @see DynamicImage::ImageReader#read
    class InvalidHeader < DynamicImage::Errors::Error; end

    # Raised when the digest in a request doesn't match the parameters.
    # Rescued as <tt>:unauthorized</tt>, so Rails renders it as 401.
    #
    # This is what an expired or hand-edited URL produces, so it's
    # usually noise rather than a sign of trouble.
    #
    # @see DynamicImage::DigestVerifier#verify
    class InvalidSignature < DynamicImage::Errors::Error; end

    # Raised when cropping is requested without both dimensions, as in
    # <tt>size: "400x", crop: true</tt>. There is no way to crop to an
    # exact size when one of them is unknown.
    #
    # @see DynamicImage::ImageSizing#fit
    class InvalidSizeOptions < DynamicImage::Errors::Error; end

    # Raised when a transformation can't be applied, either because a
    # rotation isn't a multiple of 90 degrees or because a crop falls
    # outside the image.
    #
    # @see DynamicImage::ImageProcessor::Transform
    class InvalidTransformation < DynamicImage::Errors::Error; end

    # Raised when a request is missing a parameter needed to verify the
    # signature. Like {InvalidSignature}, this is what a malformed URL
    # produces.
    #
    # @see DynamicImage::Controller
    class ParameterMissing < DynamicImage::Errors::Error; end
  end
end
