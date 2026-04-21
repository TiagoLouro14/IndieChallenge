module Api
  module V1
    class PoisController < ApplicationController
      include Pagy::Backend

      def index
        scope = Poi.includes(:categories).order(:name)
        if params[:category].present?
          scope = scope.joins(:categories).where(categories: { name: params[:category] }).distinct
        end

        pagy, pois = pagy(scope, limit: params.fetch(:per_page, 20).to_i.clamp(1, 100))
        render json: {
          data: pois.map { |p| serialize_poi(p) },
          meta: pagy_metadata(pagy)
        }
      end

      def show
        poi = Poi.includes(:categories).find(params[:id])
        render json: serialize_poi(poi)
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'POI not found' }, status: :not_found
      end

      def nearest
        lat = params[:lat]
        lng = params[:lng]

        return render json: { error: 'lat and lng required' }, status: :bad_request if lat.blank? || lng.blank?
        return render json: { error: 'invalid coordinates' }, status: :unprocessable_content unless lat.to_f.between?(
          -90, 90
        ) && lng.to_f.between?(-180, 180)

        poi = Poi.nearest(lat, lng)
        return render json: { error: 'No POIs found' }, status: :not_found unless poi

        render json: serialize_poi(poi)
      end

      private

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
