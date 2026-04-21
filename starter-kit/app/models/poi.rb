class Poi < ApplicationRecord
  has_many :poi_categories, dependent: :destroy
  has_many :categories, through: :poi_categories

  validates :name, presence: true, uniqueness: true
  validates :coordinates, presence: true

  GEO_FACTORY = RGeo::Geographic.spherical_factory(srid: 4326)

  def self.point(lat, lng)
    GEO_FACTORY.point(lng.to_f, lat.to_f)
  end

  def self.nearest(lat, lng)
    origin_sql = "ST_SetSRID(ST_MakePoint(#{lng.to_f}, #{lat.to_f}), 4326)::geography"
    order(Arel.sql("ST_Distance(coordinates::geography, #{origin_sql})")).first
  end

  MIN_STOP_DISTANCE = 5000 # metres — exclude POIs too close to origin or destination

  # Primary: POI selection along actual road geometry from OSRM
  def self.along_road_route(origin, destination, route_geojson:, limit:, categories: nil)
    ox = origin.coordinates.x
    oy = origin.coordinates.y
    dx = destination.coordinates.x
    dy = destination.coordinates.y
    origin_geo   = "ST_SetSRID(ST_MakePoint(#{ox}, #{oy}), 4326)"
    dest_geo     = "ST_SetSRID(ST_MakePoint(#{dx}, #{dy}), 4326)"
    distance_sql = "ST_Distance(pois.coordinates::geography, #{origin_geo}::geography)"
    route_sql    = connection.quote(route_geojson)
    route_geom   = "ST_GeomFromGeoJSON(#{route_sql})"

    far_from_origin = "ST_Distance(pois.coordinates::geography, #{origin_geo}::geography) > #{MIN_STOP_DISTANCE}"
    far_from_dest   = "ST_Distance(pois.coordinates::geography, #{dest_geo}::geography) > #{MIN_STOP_DISTANCE}"

    scope = select("pois.*, #{distance_sql} AS distance_from_origin")
            .where(Arel.sql("ST_DWithin(coordinates::geography, #{route_geom}::geography, 50000)"))
            .where(Arel.sql(far_from_origin))
            .where(Arel.sql(far_from_dest))
            .order(Arel.sql('distance_from_origin'))

    scope = scope.joins(:categories).where(categories: { name: categories }).distinct if categories.present?

    scope.limit(limit)
  end

  # Fallback: straight-line corridor when OSRM is unavailable
  def self.along_route(origin, destination, limit:, categories: nil)
    ox = origin.coordinates.x
    oy = origin.coordinates.y
    dx = destination.coordinates.x
    dy = destination.coordinates.y

    origin_geo = "ST_SetSRID(ST_MakePoint(#{ox}, #{oy}), 4326)"
    dest_geo   = "ST_SetSRID(ST_MakePoint(#{dx}, #{dy}), 4326)"
    route_line = "ST_MakeLine(#{origin_geo}::geometry, #{dest_geo}::geometry)"
    distance_sql = "ST_Distance(pois.coordinates::geography, #{origin_geo}::geography)"

    projection_sql = <<~SQL.squish
      ST_Distance(#{origin_geo}::geography, pois.coordinates::geography) *
      cos(
        ST_Azimuth(#{origin_geo}::geography, pois.coordinates::geography) -
        ST_Azimuth(#{origin_geo}::geography, #{dest_geo}::geography)
      ) >= -5000
    SQL

    far_from_origin = "ST_Distance(pois.coordinates::geography, #{origin_geo}::geography) > #{MIN_STOP_DISTANCE}"
    far_from_dest   = "ST_Distance(pois.coordinates::geography, #{dest_geo}::geography) > #{MIN_STOP_DISTANCE}"

    scope = select("pois.*, #{distance_sql} AS distance_from_origin")
            .joins(Arel.sql("CROSS JOIN LATERAL #{route_line} AS route(geom)"))
            .where(Arel.sql('ST_DWithin(coordinates::geography, route.geom::geography, 50000)'))
            .where(Arel.sql(projection_sql))
            .where(Arel.sql(far_from_origin))
            .where(Arel.sql(far_from_dest))
            .order(Arel.sql('distance_from_origin'))

    scope = scope.joins(:categories).where(categories: { name: categories }).distinct if categories.present?

    scope.limit(limit)
  end
end
