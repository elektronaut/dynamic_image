class ImagesController < ApplicationController
  include DynamicImage::Controller

  private

  def model
    Image
  end
end
