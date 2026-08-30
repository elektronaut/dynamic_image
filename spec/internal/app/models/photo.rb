# frozen_string_literal: true

# An image model whose name doesn't collide with the +image_path+ asset
# helper, which shadows the route helper in mailer views.
class Photo < ApplicationRecord
  include DynamicImage::Model
end
