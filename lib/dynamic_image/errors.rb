# frozen_string_literal: true

module DynamicImage
  module Errors
    class Error < StandardError; end

    class InvalidImage < DynamicImage::Errors::Error; end

    class InvalidHeader < DynamicImage::Errors::Error; end

    class InvalidSignature < DynamicImage::Errors::Error; end

    class InvalidSizeOptions < DynamicImage::Errors::Error; end

    class InvalidTransformation < DynamicImage::Errors::Error; end

    class ParameterMissing < DynamicImage::Errors::Error; end
  end
end
