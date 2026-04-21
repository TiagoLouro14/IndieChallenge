require 'rails_helper'

RSpec.describe Location, type: :model do
  subject { build(:location) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:region) }
  it { should validate_uniqueness_of(:name) }

  describe '.point' do
    it 'builds geographic point with correct coordinates' do
      point = Location.point(38.7223, -9.1393)
      expect(point.y).to be_within(0.0001).of(38.7223)
      expect(point.x).to be_within(0.0001).of(-9.1393)
    end
  end
end
