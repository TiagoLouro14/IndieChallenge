module Api
  module V1
    class LocationsController < ApplicationController
      def index
        locations = Location.order(:name)
        render json: locations.map { |l| serialize_location(l) }
      end

      def show
        location = Location.find(params[:id])
        render json: serialize_location(location)
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Location not found' }, status: :not_found
      end

      private

      def serialize_location(loc)
        {
          id: loc.id,
          name: loc.name,
          region: loc.region,
          lat: loc.coordinates&.y,
          lng: loc.coordinates&.x
        }
      end
    end
  end
end
