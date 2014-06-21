class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.belongs_to :avatar
      t.timestamps
    end
  end
end
