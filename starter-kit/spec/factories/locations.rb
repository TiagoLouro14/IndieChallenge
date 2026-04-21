FactoryBot.define do
  factory :location do
    sequence(:name) { |n| "City #{n}" }
    region { 'Lisboa' }
    coordinates { Location.point(38.7223, -9.1393) }
  end
end
