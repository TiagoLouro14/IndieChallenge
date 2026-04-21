require 'rails_helper'

RSpec.describe 'Api::V1::Trips', type: :request do
  let!(:lisbon) { create(:location, name: 'Lisboa', region: 'Lisboa', coordinates: Location.point(38.7223, -9.1393)) }
  let!(:faro)   { create(:location, name: 'Faro',   region: 'Algarve', coordinates: Location.point(37.0194, -7.9304)) }
  let!(:stop1)  { create(:poi, name: 'Stop 1', coordinates: Poi.point(38.5, -8.5)) }

  describe 'GET /api/v1/trips/plan' do
    it 'returns trip plan with stops' do
      get "/api/v1/trips/plan?origin_id=#{lisbon.id}&destination_id=#{faro.id}&limit=5"
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to have_key('origin')
      expect(body).to have_key('destination')
      expect(body).to have_key('stops')
    end

    it 'filters stops by category' do
      beach = create(:category, name: 'beach')
      stop1.categories << beach
      get "/api/v1/trips/plan?origin_id=#{lisbon.id}&destination_id=#{faro.id}&categories=beach"
      body = response.parsed_body
      expect(body['stops'].pluck('name')).to include('Stop 1')
    end

    it 'returns 422 for invalid origin' do
      get "/api/v1/trips/plan?origin_id=999999&destination_id=#{faro.id}"
      expect(response).to have_http_status(422)
    end

    it 'returns 422 for invalid destination' do
      get "/api/v1/trips/plan?origin_id=#{lisbon.id}&destination_id=999999"
      expect(response).to have_http_status(422)
    end

    it 'respects limit parameter' do
      create_list(:poi, 5, coordinates: Poi.point(38.5, -8.5))
      get "/api/v1/trips/plan?origin_id=#{lisbon.id}&destination_id=#{faro.id}&limit=2"
      body = response.parsed_body
      expect(body['stops'].size).to be <= 2
    end
  end
end
