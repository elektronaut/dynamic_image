# frozen_string_literal: true

module DynamicImage
  # = DynamicImage Schema
  #
  # The database schema {DynamicImage::Model} expects on the table
  # holding the image.
  #
  # DynamicImage doesn't own that table. Unlike
  # +dynamic_image_variants+, which has a fixed name and an engine
  # migration, the image table is created by the
  # +dynamic_image:resource+ generator in the application, under
  # whatever name the application picked, and there may be more than
  # one. This is the single definition of what it should contain.
  #
  # @see DynamicImage::Model
  module Schema
    # The expected columns, in the order they should appear in a
    # migration. Each is described by its migration type and whether it
    # accepts +NULL+.
    #
    # @return [Hash{Symbol => Hash}]
    ATTRIBUTES = {
      content_hash: { type: :string, null: false },
      content_type: { type: :string, null: false },
      content_length: { type: :integer, null: false },
      filename: { type: :string, null: false },
      colorspace: { type: :string, null: false },
      real_width: { type: :integer, null: false },
      real_height: { type: :integer, null: false },
      crop_width: { type: :integer, null: true },
      crop_height: { type: :integer, null: true },
      crop_start_x: { type: :integer, null: true },
      crop_start_y: { type: :integer, null: true },
      crop_gravity_x: { type: :integer, null: true },
      crop_gravity_y: { type: :integer, null: true }
    }.freeze

    # The expected indexes.
    #
    # @return [Array<Hash>]
    INDEXES = [
      { columns: %i[content_hash], unique: false }
    ].freeze
  end
end
