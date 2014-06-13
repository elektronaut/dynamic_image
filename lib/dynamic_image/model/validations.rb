# encoding: utf-8

module DynamicImage
  module Model
    module Validations
      extend ActiveSupport::Concern
      included do
        validates :content_type,
                  presence: true,
                  format: /\Aimage\/(gif|jpeg|pjpeg|png)\z/
      end
    end
  end
end