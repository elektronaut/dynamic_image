# encoding: utf-8

module DynamicImage
  # = DynamicImage Routing
  #
  # Extends +ActionDispatch::Routing::Mapper+ and provides a shortcut for
  # defining routes for +DynamicImage::Controller+.
  module Routing
    # Declares an image resource.
    #
    #   image_resources :avatars
    def image_resources(resource_name, options = {})
      options = {
        path:        "#{resource_name}/:digest(/:size)",
        constraints: { size: /\d+x\d+/ },
        only:        [:show]
      }.merge(options)
      resources resource_name, options do
        get :uncropped, on: :member
        get :original, on: :member
        get :download, on: :member
      end
    end
  end
end
