# encoding: utf-8

require 'dynamic_image/model/validations'

module DynamicImage
  module Model
    extend ActiveSupport::Concern
    include DynamicImage::Model::Validations
    include Shrouded::Model
  end
end