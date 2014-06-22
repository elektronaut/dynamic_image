class Post < ActiveRecord::Base
  belongs_to :image, dependent: :destroy
  validates :image, presence: true
  accepts_nested_attributes_for :image
  validates_associated :image

  validates :name, presence: true
end
