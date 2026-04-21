class CreateLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :locations do |t|
      t.string :name, null: false
      t.string :region, null: false
      t.st_point :coordinates, geographic: true, null: false

      t.timestamps
    end

    add_index :locations, :coordinates, using: :gist
    add_index :locations, :name, unique: true
  end
end
