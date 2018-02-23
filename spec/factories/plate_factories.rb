# frozen_string_literal: true

# Please note: This is a new file to help improve factory organization.
# Some plate factories may exist elsewhere, especially in the domain
# files, such as pipelines and in the catch all factory folder.
# Create all new plate factories here, and move others as you find them,
# especially if you change them, otherwise merges could get messy.

# The factories in here, at time of writing could do with a bit of TLC.
FactoryGirl.define do
  # Allows a plate to automatically generate wells. Invluded in most plate factories already
  # If you inherit from the standard plate, you do not need to include this.
  trait :with_wells do
    transient do
      sample_count { 0 } # The number of wells to create [LEGACY: use well_count instead]
      well_count { sample_count } # The number of wells to create
      well_factory :well # THe factory to use for wells
      studies { build_list(:study, 1) } # A list of studies to apply to wells.
      projects { build_list(:project, 1) } # A list of projects to apply to wells
      well_order :column_order # The order of wells on the plate. Almost always column_order
      # HELPERS: Generally you shouldn't need to use these transients
      studies_cycle { studies.cycle } # Allow us to rotate through listed studies when building out wells
      projects_cycle { projects.cycle } # Allow us to rotate through listed studies when building out wells
      well_locations { maps.where(well_order => (0...well_count)) }
    end

    after(:build) do |plate, evaluator|
      plate.wells = evaluator.well_locations.map do |map|
        build(evaluator.well_factory, map: map, study: evaluator.studies_cycle.next, project: evaluator.projects_cycle.next)
      end
    end
  end

  factory :plate do
    plate_purpose
    name 'Plate name'
    value ''
    qc_state ''
    resource nil
    barcode
    size 96

    with_wells

    factory :input_plate do
      association(:plate_purpose, factory: :input_plate_purpose)
    end

    factory :target_plate do
      transient do
        parent { build :input_plate }
        submission { build :submission }
      end

      after(:build) do |plate, evaluator|
        well_hash = evaluator.parent.wells.index_by(&:map_description)
        plate.wells.each do |well|
          well.stock_well_links << build(:stock_well_link, target_well: well, source_well: well_hash[well.map_description])
          create :transfer_request, asset: well_hash[well.map_description], target_asset: well, submission: evaluator.submission
        end
      end
    end

    factory :plate_with_untagged_wells do
      transient do
        sample_count 8
        well_factory :untagged_well
      end
    end

    factory :plate_with_tagged_wells do
      transient do
        sample_count 8
        well_factory :tagged_well
      end
    end

    factory :plate_with_empty_wells do
      transient { well_count 8 }
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
  end

  # StripTubes are effectively thin plates
  factory :strip_tube do
    name               'Strip_tube'
    size               8
    plate_purpose      { create :strip_tube_purpose }
    after(:create) do |st|
      st.wells = st.maps.map { |map| create(:well, map: map) }
    end
  end
end
