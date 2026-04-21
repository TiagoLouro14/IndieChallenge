class CreatePoiCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :poi_categories do |t|
      t.references :poi, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
  end
end
