# frozen_string_literal: true

FactoryBot.define do
  factory :pooled_plate_creation do
    # Without this, create_children! tries to go to Baracoda for a barcode.
    sanger_barcode { create(:plate_barcode) }

    child_purpose { |target| target.association(:plate_purpose) }
    parents { |target| [target.association(:plate), target.association(:tube)] }
    user { |target| target.association(:user) }
  end
end
