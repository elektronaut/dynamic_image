# encoding: utf-8

module DynamicImage
  module Errors
    class Error < StandardError; end
    class InvalidImage < DynamicImage::Errors::Error; end
    class InvalidSignature < DynamicImage::Errors::Error; end
    class InvalidSizeOptions < DynamicImage::Errors::Error; end
  end
end