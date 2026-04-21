require 'rails_helper'

RSpec.describe PoiCategory, type: :model do
  it { should belong_to(:poi) }
  it { should belong_to(:category) }
end
