# encoding: utf-8

module DynamicImage
  # = DynamicImage Belongs To
  #
  module BelongsTo
    extend ActiveSupport::Concern

    module ClassMethods
      def belongs_to_image(name, scope=nil, options={})
        belongs_to(name, scope, options)

        define_method "#{name}=" do |new_image|
          if new_image.present? && !new_image.kind_of?(DynamicImage::Model)
            new_image = self.send("build_#{name}", file: new_image)
          end
          super(new_image)
        end
      end
    end
  end
end