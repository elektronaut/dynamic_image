class ImagesController < ActionController::Base
  include DynamicImage::Controller

  private

  def model
    Image
  end
end