# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Routing
  #
  # Extends +ActionDispatch::Routing::Mapper+ and provides a shortcut for
  # defining routes for +DynamicImage::Controller+.
  module Routing
    # Declares an image resource, routing +show+ along with the
    # +uncropped+, +original+ and +download+ member actions.
    #
    # The default path includes the digest and an optional size. Pass
    # +:path+ to change it, which you'll want to do if the resource
    # collides with a directory in +public+.
    #
    # @param resource_name [Symbol, String] the resource
    # @param options [Hash] options passed to +resources+, merged over
    #   the defaults
    # @return [void]
    #
    # @example
    #   image_resources :avatars
    #
    # @example Keeping clear of public/images
    #   image_resources :images, path: "dynamic_images/:digest(/:size)"
    def image_resources(resource_name, options = {})
      options = {
        path: "#{resource_name}/:digest(/:size)",
        constraints: { size: /\d+x\d+/ },
        only: %i[show]
      }.merge(options)

      resources resource_name, **options do
        get :uncropped, on: :member
        get :original, on: :member
        get :download, on: :member
      end
    end
  end
end
