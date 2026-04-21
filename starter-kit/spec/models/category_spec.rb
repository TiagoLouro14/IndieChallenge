require 'rails_helper'

RSpec.describe Category, type: :model do
  subject { build(:category) }

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }
  it { should have_many(:poi_categories).dependent(:destroy) }
  it { should have_many(:pois).through(:poi_categories) }
end
