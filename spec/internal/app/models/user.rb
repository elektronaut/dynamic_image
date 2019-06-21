# frozen_string_literal: true

class User < ApplicationRecord
  belongs_to_image :avatar, class_name: "Image"
  validates_associated :avatar
end
