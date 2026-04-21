FactoryBot.define do
  factory :poi do
    sequence(:name) { |n| "POI #{n}" }
    description { 'A nice place' }
    coordinates { Poi.point(38.7223, -9.1393) }
  end
end
