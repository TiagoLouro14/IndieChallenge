ActiveRecord::Schema[8.1].define(version: 2026_04_20_175827) do
  enable_extension "postgis"

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "locations", force: :cascade do |t|
    t.string "name", null: false
    t.string "region", null: false
    t.geography "coordinates", limit: { srid: 4326, type: "st_point", geographic: true }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coordinates"], name: "index_locations_on_coordinates", using: :gist
    t.index ["name"], name: "index_locations_on_name", unique: true
  end

  create_table "pois", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.geography "coordinates", limit: { srid: 4326, type: "st_point", geographic: true }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coordinates"], name: "index_pois_on_coordinates", using: :gist
    t.index ["name"], name: "index_pois_on_name", unique: true
  end

  create_table "poi_categories", force: :cascade do |t|
    t.bigint "poi_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["poi_id"], name: "index_poi_categories_on_poi_id"
    t.index ["category_id"], name: "index_poi_categories_on_category_id"
  end

  add_foreign_key "poi_categories", "categories"
  add_foreign_key "poi_categories", "pois"
end
