# frozen_string_literal: true

require "rails/generators"
require "rails/generators/rails/resource/resource_generator"

module DynamicImage
  # Generators for setting up DynamicImage in an application.
  module Generators
    # Creates a DynamicImage resource: a model including
    # {DynamicImage::Model}, a controller including
    # {DynamicImage::Controller}, a migration with the columns
    # DynamicImage needs, and an +image_resources+ route.
    #
    #   bin/rails generate dynamic_image:resource image
    #
    # Additional attributes are passed through to the migration, so a
    # resource can carry fields of its own.
    #
    #   bin/rails generate dynamic_image:resource photo caption:string
    class ResourceGenerator < Rails::Generators::ResourceGenerator
      source_root File.expand_path("templates", __dir__)

      def initialize(args, *options)
        super(inject_dynamic_image_attributes(args), *options)
      end

      def add_controller_extension
        inject_into_class(
          File.join("app/controllers",
                    class_path,
                    "#{file_name.pluralize}_controller.rb"),
          "#{class_name.pluralize}Controller"
        ) do
          "  include DynamicImage::Controller\n\n  private\n\n  " \
            "def model\n    #{class_name}\n  end\n"
        end
      end

      def add_model_extension
        inject_into_class(
          File.join("app/models", class_path, "#{file_name}.rb"),
          class_name
        ) do
          "  include DynamicImage::Model\n"
        end
      end

      def alter_resource_routes
        gsub_file(
          File.join("config", "routes.rb"),
          " resources :#{file_name.pluralize}",
          " image_resources :#{file_name.pluralize}"
        )
      end

      private

      def inject_dynamic_image_attributes(args)
        if args.any?
          [args[0]] + dynamic_image_attributes + args[1..args.length]
        else
          args
        end
      end

      def dynamic_image_attributes
        %w[content_hash:string content_type:string
           content_length:integer
           filename:string
           colorspace:string
           real_width:integer real_height:integer
           crop_width:integer crop_height:integer
           crop_start_x:integer crop_start_y:integer
           crop_gravity_x:integer crop_gravity_y:integer]
      end
    end
  end
end
