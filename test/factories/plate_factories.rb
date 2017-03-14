# Please note: This is a new file to help improve factory organization.
# Some plate factories may exist elsewhere, especially in the domain
# files, such as pipelines and in the catch all factory folder.
# Create all new plate factories here, and move others as you find them,
# especially if you change them, otherwise merges could get messy.

# The factories in here, at time of writing could do with a bit of TLC.
FactoryGirl.define do
  factory :plate do
    plate_purpose
    name 'Plate name'
    value               ''
    qc_state            ''
    resource            nil
    barcode
    size 96

    transient do
      well_count { 0 }
      well_locations { Map.where_plate_size(size).where_plate_shape(AssetShape.default).where(column_order: (0...well_count)) }
    end

    after(:build) do |plate, evaluator|
      plate.wells = evaluator.well_locations.map do |map|
        build(:well, map: map)
      end
    end

    factory :input_plate do
      association(:plate_purpose, factory: :input_plate_purpose)
    end

    factory :target_plate do
      transient do
        parent { build :input_plate }
      end

      after(:build) do |plate, evaluator|
        well_hash = Hash[evaluator.parent.wells.map { |w| [w.map_description, w] }]
        plate.wells.each do |well|
          well.stock_well_links << build(:stock_well_link, target_well: well, source_well: well_hash[well.map_description])
        end
      end
    end

    factory :source_plate do
      plate_purpose { |pp| pp.association(:source_plate_purpose) }
    end

    factory :child_plate do
      transient do
        parent { create(:source_plate) }
      end

      plate_purpose { |pp| pp.association(:plate_purpose, source_purpose: parent.purpose) }

      after(:create) do |child_plate, evaluator|
        child_plate.parents << evaluator.parent
        child_plate.purpose.source_purpose = evaluator.parent.purpose
      end
    end

    factory :plate_with_untagged_wells do
      transient do
        sample_count 8
        occupied_map_locations do
          Map.where_plate_size(size).where_plate_shape(AssetShape.default).where(well_order => (0...sample_count))
        end
        well_order :column_order
      end

      after(:create) do |plate, evaluator|
        plate.wells = evaluator.occupied_map_locations.map do |map|
          create(:untagged_well, map: map)
        end
      end
    end

    factory :plate_with_empty_wells do
      transient do
        well_count 8
        occupied_map_locations do
          Map.where_plate_size(size).where_plate_shape(AssetShape.default).where(column_order: (0...well_count))
        end
      end

      after(:create) do |plate, evaluator|
        plate.wells = evaluator.occupied_map_locations.map do |map|
          create(:empty_well, map: map)
        end
      end
    end
  end
end
