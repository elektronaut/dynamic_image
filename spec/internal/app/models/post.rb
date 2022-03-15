# frozen_string_literal: true

class Post < ApplicationRecord
  belongs_to :image, dependent: :destroy
  accepts_nested_attributes_for :image
  validates_associated :image

  validates :name, presence: true
end
