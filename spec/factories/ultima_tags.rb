# frozen_string_literal: true

FactoryBot.define do
  factory :ultima_tag_group do
    tag_group
    barcode_plate_num { 1 }
  end

  factory :ultima_tag do
    tag
    index_barcode_num { 'Z0001' }
    barcode_plate_well { 'A1' }
  end
end
