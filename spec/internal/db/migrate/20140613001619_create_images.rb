class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      # Dis attributes
      t.string  :content_hash, null: false
      t.string  :content_type, null: false
      t.integer :content_length, null: false
      t.string  :filename, null: false

      # DynamicImage attributes
      t.string :colorspace, null: false
      t.integer :real_width, :real_height, null: false
      t.integer :crop_width, :crop_height
      t.integer :crop_start_x, :crop_start_y
      t.integer :crop_gravity_x, :crop_gravity_y

      t.timestamps
    end
  end
end
