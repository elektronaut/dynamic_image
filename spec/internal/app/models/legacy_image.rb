# frozen_string_literal: true

# An image whose table predates the frame_count and alpha columns.
class LegacyImage < ApplicationRecord
  include DynamicImage::Model
end
