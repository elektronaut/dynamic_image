# frozen_string_literal: true

class CreateDynamicImageVariants < ActiveRecord::Migration[5.2]
  def change
    create_table :dynamic_image_variants do |t|
      t.references :image, polymorphic: true, null: false

      # Dis attributes
      t.string  :content_hash, null: false
      t.string  :content_type, null: false
      t.integer :content_length, null: false
      t.string  :filename, null: false

      t.string :format, null: false
      t.integer :width, :height, null: false
      t.integer :crop_width, :crop_height, null: false
      t.integer :crop_start_x, :crop_start_y, null: false

      t.timestamps null: false
    end

    add_index(:dynamic_image_variants,
              %i[image_id image_type],
              name: "dynamic_image_variants_by_image")

    add_index(:dynamic_image_variants,
              %i[image_id image_type format width height crop_width
                 crop_height crop_start_x crop_start_y],
              name: "dynamic_image_variants_by_format_and_size",
              unique: true)
  end
end
