# encoding: utf-8

require 'mini_magick'
require 'shrouded'
require 'vector2d'

require 'dynamic_image/belongs_to'
require 'dynamic_image/controller'
require 'dynamic_image/digest_verifier'
require 'dynamic_image/errors'
require 'dynamic_image/helper'
require 'dynamic_image/image_sizing'
require 'dynamic_image/metadata'
require 'dynamic_image/model'
require 'dynamic_image/processed_image'
require 'dynamic_image/railtie'
require 'dynamic_image/routing'

module DynamicImage
  cattr_accessor :digest_verifier
end
