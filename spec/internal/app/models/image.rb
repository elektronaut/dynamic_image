# frozen_string_literal: true

class Image < ApplicationRecord
  include DynamicImage::Model
end
