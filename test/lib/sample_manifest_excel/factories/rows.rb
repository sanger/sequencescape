FactoryGirl.define do

  factory :row, class: SampleManifestExcel::Upload::Row do

    ignore do
      sample { create(:sample_with_well)}
    end

    sequence(:number)   { |n| n }
    columns             { build(:column_list_for_plate) }
    data                { columns.column_values(
                        sanger_sample_id: sample.id,
                        sanger_plate_id: sample.wells.first.plate.sanger_human_barcode,
                        well: sample.wells.first.map.description
                        ) }

    initialize_with { new(number, data, columns) }

  end
end