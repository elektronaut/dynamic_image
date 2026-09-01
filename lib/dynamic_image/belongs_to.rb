# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Belongs To
  #
  # Extends ActiveRecord with {ClassMethods#belongs_to_image}, an association that accepts an uploaded file in place
  # of a record.
  #
  # The engine mixes this into +ActiveRecord::Base+, so it is available in any model.
  module BelongsTo
    extend ActiveSupport::Concern

    module ClassMethods
      # Declares an association to an image. Behaves like +belongs_to+ and takes the same arguments, with one
      # addition: assigning anything that isn't a {DynamicImage::Model} builds the associated record from it,
      # treating it as an uploaded file. A file can therefore be posted straight to the parent model.
      #
      # The image is built, not saved, and is written when the parent is. Add +validates_associated+ if an invalid
      # upload should invalidate the parent; without it the assignment is silently dropped on save.
      #
      # @param name [Symbol] the name of the association
      # @param scope [Proc, nil] an optional scope, as +belongs_to+
      # @return [void]
      #
      # @example
      #   class User < ActiveRecord::Base
      #     belongs_to_image :avatar, class_name: "Image"
      #     validates_associated :avatar
      #   end
      #
      #   User.create(avatar: params[:file])
      def belongs_to_image(name, scope = nil, **)
        belongs_to(name, scope, **)

        define_method "#{name}=" do |new_image|
          if new_image.present? && !new_image.is_a?(DynamicImage::Model)
            new_image = send("build_#{name}", file: new_image)
          end
          super(new_image)
        end
      end
    end
  end
end
