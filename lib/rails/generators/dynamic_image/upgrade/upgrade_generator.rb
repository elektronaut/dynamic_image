# frozen_string_literal: true

require "rails/generators"
require "rails/generators/named_base"
require "rails/generators/active_record/migration"

require "dynamic_image/schema"

module DynamicImage
  module Generators
    # Brings an existing table up to date with {DynamicImage::Schema}.
    #
    #   bin/rails generate dynamic_image:upgrade Image
    #
    # The migration is derived from the difference between the table and
    # the schema, so running it again once the migration has been
    # applied writes nothing. An application several releases behind
    # gets a single migration with everything it's missing.
    #
    # Only additive changes are generated. Columns are added nullable and
    # nullability differences are reported instead of altered:
    # +change_column_null+ fails on existing NULLs, and whether the data
    # allows it isn't something the generator can know.
    class UpgradeGenerator < Rails::Generators::NamedBase
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      def create_upgrade_migration
        if missing_columns.empty? && missing_indexes.empty?
          say_status(:identical, "#{table_name} is up to date", :blue)
          return
        end

        migration_template("upgrade_migration.rb",
                           File.join(db_migrate_path, "#{migration_name}.rb"))
      end

      def report_nullability
        nullable_in_table.each do |name|
          say_status(:warn,
                     "#{table_name}.#{name} should be NOT NULL",
                     :yellow)
        end
      end

      def report_index_locking
        return if missing_indexes.empty?

        say_status(:warn,
                   "adding an index locks the table while it builds",
                   :yellow)
      end

      private

      def model_class
        @model_class ||= class_name.constantize
      end

      def table_name
        model_class.table_name
      end

      def existing_columns
        @existing_columns ||= model_class.columns.index_by { |c| c.name.to_sym }
      end

      def existing_indexes
        @existing_indexes ||=
          model_class.connection.indexes(table_name).map do |index|
            Array(index.columns).map(&:to_sym)
          end
      end

      def missing_columns
        @missing_columns ||=
          DynamicImage::Schema::ATTRIBUTES.reject do |name, _|
            existing_columns.key?(name)
          end
      end

      # An index whose leading columns match already answers the query,
      # so only a missing prefix counts as missing.
      def missing_indexes
        @missing_indexes ||=
          DynamicImage::Schema::INDEXES.reject do |index|
            columns = index[:columns]
            existing_indexes.any? { |e| e.first(columns.length) == columns }
          end
      end

      def nullable_in_table
        DynamicImage::Schema::ATTRIBUTES.filter_map do |name, column|
          existing = existing_columns[name]
          name if existing && !column[:null] && existing.null
        end
      end

      def index_columns(index)
        columns = index[:columns]
        columns.length == 1 ? columns.first.inspect : columns.inspect
      end

      def migration_name
        if missing_columns.any?
          "add_#{missing_columns.keys.join('_and_')}_to_#{table_name}"
        else
          "add_dynamic_image_indexes_to_#{table_name}"
        end
      end
    end
  end
end
