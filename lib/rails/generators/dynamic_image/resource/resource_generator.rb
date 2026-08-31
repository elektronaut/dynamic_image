# frozen_string_literal: true

require "rails/generators"
require "rails/generators/rails/resource/resource_generator"
require "rails/generators/active_record/migration"

require "dynamic_image/schema"

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
    #
    # The migration is rendered from {DynamicImage::Schema} rather than
    # by the Active Record generator, which can't express nullability
    # or indexes through its +name:type+ arguments.
    class ResourceGenerator < Rails::Generators::ResourceGenerator
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      def initialize(args, *options)
        @orm_args = args
        super
      end

      no_commands do
        # Thor consumes the raw arguments while parsing, so they're kept
        # from {#initialize} to pass on to the ORM generator.
        def invoke_orm_generator(orm)
          invoke(orm, @orm_args, options.merge("migration" => false))
        end
      end

      # The ORM generator would write its own migration, which can't
      # carry nullability or indexes. Invoke it with +migration: false+
      # and render {#create_dynamic_image_migration} instead.
      hook_for :orm, required: true, in: :rails, as: :model do |instance, orm|
        instance.invoke_orm_generator(orm)
      end

      def create_dynamic_image_migration
        migration_template(
          "create_table_migration.rb",
          File.join(db_migrate_path, "create_#{table_name}.rb")
        )
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

      def schema_attributes
        DynamicImage::Schema::ATTRIBUTES
      end

      def schema_indexes
        DynamicImage::Schema::INDEXES
      end

      def index_columns(index)
        columns = index[:columns]
        columns.length == 1 ? columns.first.inspect : columns.inspect
      end

      def attributes_with_index
        attributes.select { |a| !a.reference? && a.has_index? }
      end
    end
  end
end
