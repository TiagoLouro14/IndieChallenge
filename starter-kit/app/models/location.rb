class Location < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :region, presence: true
  validates :coordinates, presence: true

  GEO_FACTORY = RGeo::Geographic.spherical_factory(srid: 4326)

  def self.point(lat, lng)
    GEO_FACTORY.point(lng.to_f, lat.to_f)
  end
end
