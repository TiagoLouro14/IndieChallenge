require 'rails_helper'

RSpec.describe 'Api::V1::Locations', type: :request do
  let!(:lisbon) { create(:location, name: 'Lisboa', region: 'Lisboa', coordinates: Location.point(38.72, -9.13)) }
  let!(:porto)  { create(:location, name: 'Porto',  region: 'Norte',  coordinates: Location.point(41.15, -8.62)) }

  describe 'GET /api/v1/locations' do
    it 'returns all locations ordered by name' do
      get '/api/v1/locations'
      expect(response).to have_http_status(:ok)
      names = response.parsed_body.pluck('name')
      expect(names).to eq(%w[Lisboa Porto])
    end

    it 'returns lat/lng fields' do
      get '/api/v1/locations'
      data = response.parsed_body.first
      expect(data).to include('lat', 'lng', 'name', 'region')
    end
  end

  describe 'GET /api/v1/locations/:id' do
    it 'returns location' do
      get "/api/v1/locations/#{lisbon.id}"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['name']).to eq('Lisboa')
    end

    it 'returns 404 for missing location' do
      get '/api/v1/locations/999999'
      expect(response).to have_http_status(:not_found)
    end
  end
end
