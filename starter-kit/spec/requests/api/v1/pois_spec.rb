require 'rails_helper'

RSpec.describe 'Api::V1::Pois', type: :request do
  let!(:beach_cat) { create(:category, name: 'beach') }
  let!(:poi_a) do
    create(:poi, name: 'Praia A', coordinates: Poi.point(37.09, -8.41)).tap do |p|
      p.categories << beach_cat
    end
  end
  let!(:poi_b) { create(:poi, name: 'Castle B', coordinates: Poi.point(38.71, -9.13)) }

  describe 'GET /api/v1/pois' do
    it 'returns paginated pois' do
      get '/api/v1/pois'
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to have_key('data')
      expect(body).to have_key('meta')
    end

    it 'filters by category' do
      get '/api/v1/pois?category=beach'
      data = response.parsed_body['data']
      expect(data.pluck('name')).to include('Praia A')
      expect(data.pluck('name')).not_to include('Castle B')
    end
  end

  describe 'GET /api/v1/pois/:id' do
    it 'returns poi with categories' do
      get "/api/v1/pois/#{poi_a.id}"
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['categories']).to include('beach')
    end

    it 'returns 404 for missing poi' do
      get '/api/v1/pois/999999'
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/v1/pois/nearest' do
    it 'returns nearest poi to coordinates' do
      get '/api/v1/pois/nearest?lat=37.09&lng=-8.41'
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['name']).to eq('Praia A')
    end

    it 'returns 400 without coordinates' do
      get '/api/v1/pois/nearest'
      expect(response).to have_http_status(:bad_request)
    end
  end
end
