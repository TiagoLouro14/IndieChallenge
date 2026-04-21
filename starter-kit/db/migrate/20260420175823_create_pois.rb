class CreatePois < ActiveRecord::Migration[8.1]
  def change
    create_table :pois do |t|
      t.string :name, null: false
      t.text :description
      t.st_point :coordinates, geographic: true, null: false

      t.timestamps
    end

    add_index :pois, :coordinates, using: :gist
    add_index :pois, :name, unique: true
  end
end
