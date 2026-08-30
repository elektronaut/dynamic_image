# frozen_string_literal: true

# Mailer views only get +_url+ helpers, so the view passes
# <tt>routing_type: :url</tt>.
class PhotoMailer < ApplicationMailer
  def photo(photo)
    @photo = photo
    mail(to: "recipient@example.com")
  end
end
