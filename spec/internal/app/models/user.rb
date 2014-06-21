class User < ActiveRecord::Base
  belongs_to_image :avatar, class_name: 'Image'
  validates_associated :avatar
end
