# frozen_string_literal: true

FactoryBot.define do
  factory(:plate_creation) do
    # Without this, create_children! tries to go to Baracoda for a barcode.
    sanger_barcode { create(:sequencescape22) }

    child_purpose factory: %i[plate_purpose]
    parent factory: %i[full_plate], well_count: 2
    user
  end
end
