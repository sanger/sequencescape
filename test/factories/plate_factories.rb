# Please note: This is a new file to help improve factory organization.
# Some plate factories may exist elsewhere, especially in the domain
# files, such as pipelines and in the catch all factory folder.
# Create all new plate factories here, and move others as you find them,
# especially if you change them, otherwise merges could get messy.

# The factories in here, at time of writing could do with a bit of TLC.
FactoryGirl.define do
  factory :plate do
    plate_purpose
    name                "Plate name"
    value               ""
    qc_state            ""
    resource            nil
    barcode
    size 96

    factory :legacy_stock_plate do
      # Note: This is an unfortunate side effect of the way the stock plate purpose
      # is used throughout Sequencescape.
      plate_purpose { PlatePurpose.find_by(name: 'Stock plate') }
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
      end

      after(:create) do |plate, evaluator|
        (0...evaluator.sample_count).map do |vertical_index|
          map = Map.where_plate_size(plate.size).where_plate_shape(AssetShape.find_by_name('Standard')).where(column_order: vertical_index).first or raise StandardError
          create(:untagged_well, map: map, plate: plate)
        end
      end
    end
  end

end
