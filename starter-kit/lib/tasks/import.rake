require 'csv'

namespace :import do
  desc 'Import locations and POIs from CSV files (idempotent)'
  task all: %i[locations pois]

  task locations: :environment do
    puts 'Importing locations...'
    csv_path = Rails.root.join('data/locations.csv')
    CSV.foreach(csv_path, headers: true) do |row|
      Location.find_or_initialize_by(name: row['name']).tap do |loc|
        loc.region = row['region']
        loc.coordinates = Location.point(row['lat'], row['lng'])
        loc.save!
      end
    end
    puts "Done: #{Location.count} locations."
  end

  task pois: :environment do
    puts 'Importing POIs...'
    csv_path = Rails.root.join('data/pois.csv')
    CSV.foreach(csv_path, headers: true) do |row|
      poi = Poi.find_or_initialize_by(name: row['name'])
      poi.description  = row['description']
      poi.coordinates  = Poi.point(row['lat'], row['lng'])
      poi.save!

      category_names = row['categories'].to_s.split(',').map(&:strip).reject(&:empty?)
      category_names.each do |cat_name|
        category = Category.find_or_create_by!(name: cat_name)
        PoiCategory.find_or_create_by!(poi: poi, category: category)
      end
    end
    puts "Done: #{Poi.count} POIs, #{Category.count} categories."
  end
end
