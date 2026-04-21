require 'rails_helper'

RSpec.describe Poi, type: :model do
  subject { build(:poi) }

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }
  it { should have_many(:poi_categories).dependent(:destroy) }
  it { should have_many(:categories).through(:poi_categories) }

  describe '.nearest' do
    it 'returns closest poi to given coordinates' do
      close = create(:poi, coordinates: Poi.point(38.72, -9.13))
      _far  = create(:poi, coordinates: Poi.point(41.15, -8.62))
      expect(Poi.nearest(38.72, -9.13)).to eq(close)
    end
  end

  describe '.along_route' do
    let!(:lisbon)    { create(:location, coordinates: Location.point(38.7223, -9.1393)) }
    let!(:faro)      { create(:location, coordinates: Location.point(37.0194, -7.9304)) }
    let!(:on_route)  { create(:poi, coordinates: Poi.point(38.5, -8.5)) }
    let!(:off_route) { create(:poi, coordinates: Poi.point(41.15, -8.62)) }

    it 'returns pois within buffer of route' do
      results = Poi.along_route(lisbon, faro, limit: 5)
      expect(results).to include(on_route)
      expect(results).not_to include(off_route)
    end

    it 'filters by category' do
      beach = create(:category, name: 'beach')
      on_route.categories << beach
      results = Poi.along_route(lisbon, faro, limit: 5, categories: ['beach'])
      expect(results).to include(on_route)
    end

    it 'respects limit' do
      create_list(:poi, 3, coordinates: Poi.point(38.5, -8.5))
      results = Poi.along_route(lisbon, faro, limit: 2)
      expect(results.size).to be <= 2
    end
  end
end
