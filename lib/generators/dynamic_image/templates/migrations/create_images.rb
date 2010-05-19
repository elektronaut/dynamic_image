class CreateImages < ActiveRecord::Migration
  def self.up
    create_table :images do |t|
      t.column :name,          :string
      t.column :filename,      :string
      t.column :byline,        :string
      t.column :description,   :text
      t.column :content_type,  :string
      t.column :original_size, :string
      t.column :hotspot,       :string
      t.column :sha1_hash,     :string
      t.column :cropped,       :boolean, :null => false, :default => false
      t.column :crop_start,    :string
      t.column :crop_size,     :string
      t.column :created_at,    :datetime
      t.column :updated_at,    :datetime
      t.column :filters,       :text
    end
  end

  def self.down
    drop_table :images
  end
end
