require 'net/http'
require 'json'

module Api
  module V1
    class TripsController < ApplicationController
      OSRM_BASE    = 'https://router.project-osrm.org/route/v1/driving'.freeze
      OSRM_TIMEOUT = 5

      def plan
        origin      = Location.find_by(id: params[:origin_id])
        destination = Location.find_by(id: params[:destination_id])
        limit       = params.fetch(:limit, 5).to_i.clamp(1, 50)
        categories  = params[:categories].presence&.split(',')&.map(&:strip)

        errors = []
        errors << 'origin_id not found' unless origin
        errors << 'destination_id not found' unless destination
        return render json: { errors: errors }, status: :unprocessable_content if errors.any?

        route_geojson = fetch_osrm_geometry(origin, destination)

        pois = if route_geojson
                 Poi.along_road_route(origin, destination, route_geojson: route_geojson, limit: limit,
                                                           categories: categories)
               else
                 Poi.along_route(origin, destination, limit: limit, categories: categories)
               end
        pois = pois.preload(:categories)

        all_waypoints = [[origin.coordinates.x, origin.coordinates.y]] +
                        pois.map { |p| [p.coordinates.x, p.coordinates.y] } +
                        [[destination.coordinates.x, destination.coordinates.y]]

        route_legs = fetch_osrm_legs(all_waypoints)

        render json: {
          origin: serialize_location(origin),
          destination: serialize_location(destination),
          stops: pois.map { |p| serialize_poi(p) },
          route_legs: route_legs
        }
      end

      private

      # 2-point call — used to get corridor geometry for POI selection
      def fetch_osrm_geometry(origin, destination)
        ox = "#{origin.coordinates.x},#{origin.coordinates.y}"
        dx = "#{destination.coordinates.x},#{destination.coordinates.y}"
        coords = "#{ox};#{dx}"
        uri = URI("#{OSRM_BASE}/#{coords}?overview=full&geometries=geojson")
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                                       open_timeout: OSRM_TIMEOUT, read_timeout: OSRM_TIMEOUT) do |http|
          http.get(uri.request_uri)
        end
        data = JSON.parse(response.body)
        data.dig('routes', 0, 'geometry')&.to_json
      rescue StandardError
        nil
      end

      # N-waypoint call — returns per-leg coordinate arrays for frontend rendering
      def fetch_osrm_legs(waypoints)
        coords = waypoints.map { |w| "#{w[0]},#{w[1]}" }.join(';')
        uri = URI("#{OSRM_BASE}/#{coords}?overview=false&steps=true&geometries=geojson")
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                                       open_timeout: OSRM_TIMEOUT, read_timeout: OSRM_TIMEOUT) do |http|
          http.get(uri.request_uri)
        end
        data  = JSON.parse(response.body)
        legs  = data.dig('routes', 0, 'legs')
        return nil unless legs

        legs.map { |leg| leg['steps'].flat_map { |s| s['geometry']['coordinates'] } }
      rescue StandardError
        nil
      end

      def serialize_location(loc)
        { id: loc.id, name: loc.name, region: loc.region, lat: loc.coordinates&.y, lng: loc.coordinates&.x }
      end

      def serialize_poi(poi)
        {
          id: poi.id,
          name: poi.name,
          description: poi.description,
          lat: poi.coordinates&.y,
          lng: poi.coordinates&.x,
          categories: poi.categories.map(&:name)
        }
      end
    end
  end
end
