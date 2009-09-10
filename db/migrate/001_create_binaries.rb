class CreateBinaries < ActiveRecord::Migration
  def self.up
    create_table :binaries do |t|
      t.column :data, :binary, :limit => 100.megabytes
    end
  end

  def self.down
    drop_table :binaries
  end
end
