# encoding: utf-8

module DynamicImage
  module Model
    module Validations
      extend ActiveSupport::Concern
      included do
        validates :data,
          presence: true
        validates :content_type,
          presence: true,
          format: /\Aimage\/(gif|jpeg|pjpeg|png)\z/
        validates :content_length,
          presence: true,
          numericality: { greater_than: 0 }
        validates :filename,
          presence: true,
          length: { maximum: 255 }
        validates :real_size, :crop_size, :crop_start,
          presence: true,
          format: /\A\d+x\d+\z/
      end
    end
  end
end