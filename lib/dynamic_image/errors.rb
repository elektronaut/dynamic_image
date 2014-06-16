# encoding: utf-8

module DynamicImage
  module Errors
    class Error < StandardError; end
    class InvalidImageError < DynamicImage::Errors::Error; end
  end
end