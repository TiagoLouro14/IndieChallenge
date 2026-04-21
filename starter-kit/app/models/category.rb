class Category < ApplicationRecord
  has_many :poi_categories, dependent: :destroy
  has_many :pois, through: :poi_categories

  validates :name, presence: true, uniqueness: true
end
