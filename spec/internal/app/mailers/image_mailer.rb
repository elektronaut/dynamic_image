# frozen_string_literal: true

class ImageMailer < ApplicationMailer
  def image(image)
    @image = image
    mail(to: "recipient@example.com")
  end
end
