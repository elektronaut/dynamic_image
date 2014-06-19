# encoding: utf-8

module DynamicImage
  module Routing
    def image_resources(resource_name, options={})
      options = {
        path:        "#{resource_name}/:digest(/:size)",
        constraints: { size: /\d+x\d+/ },
        only:        [:show]
      }.merge(options)
      resources resource_name, options do
        get :uncropped, on: :member
        get :original, on: :member
      end
    end
  end
end
