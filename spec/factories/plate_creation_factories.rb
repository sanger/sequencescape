# frozen_string_literal: true

FactoryBot.define do
  factory(:plate_creation) do
    user
    sanger_barcode { create(:sequencescape22) }
    parent factory: %i[full_plate], well_count: 2
    child_purpose factory: %i[plate_purpose]
  end
end
