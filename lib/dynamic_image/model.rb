# encoding: utf-8

require 'dynamic_image/model/dimensions'
require 'dynamic_image/model/validations'

module DynamicImage
  module Model
    extend ActiveSupport::Concern
    include Shrouded::Model
    include DynamicImage::Model::Dimensions
    include DynamicImage::Model::Validations
  end
end