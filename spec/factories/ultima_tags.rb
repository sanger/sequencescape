# frozen_string_literal: true

FactoryBot.define do
  factory :ultima_tag_group do
    tag_group
    barcode_plate_num { 1 }

    transient do
      # Ultima data of tags of the tag group, as in the record files:
      # { map_id => [index_barcode_num, barcode_plate_well] }.
      ultima_tags { {} }
    end

    after(:create) do |ultima_tag_group, evaluator|
      tags = ultima_tag_group.tag_group.tags.index_by(&:map_id)
      evaluator.ultima_tags.each do |map_id, (z_number, well)|
        create(:ultima_tag, tag: tags.fetch(map_id),
                            index_barcode_num: z_number,
                            barcode_plate_well: well)
      end
    end
  end

  factory :ultima_tag do
    tag
    index_barcode_num { 'Z0001' }
    barcode_plate_well { 'A1' }
  end
end
