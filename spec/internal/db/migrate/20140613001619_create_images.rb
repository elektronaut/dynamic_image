class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      # Shrouded attributes
      t.string  :content_hash, null: false
      t.string  :content_type, null: false
      t.integer :content_length, null: false
      t.string  :filename, null: false

      # DynamicImage attributes
      t.string :real_size, null: false
      t.string :crop_start, null: false
      t.string :crop_size, null: false

      t.timestamps
    end
  end
end
