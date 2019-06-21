# frozen_string_literal: true

class ImagesController < ApplicationController
  include DynamicImage::Controller

  private

  def model
    Image
  end
end
