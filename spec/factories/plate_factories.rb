# frozen_string_literal: true

# Please note: This is a new file to help improve factory organization.
# Some plate factories may exist elsewhere, especially in the domain
# files, such as pipelines and in the catch all factory folder.
# Create all new plate factories here, and move others as you find them,
# especially if you change them, otherwise merges could get messy.

# The factories in here, at time of writing could do with a bit of TLC.
FactoryBot.define do
  # Allows a plate to automatically generate wells. Included in most plate factories already
  # If you inherit from the standard plate, you do not need to include this.

  trait :with_wells do
    transient do
      sample_count { 0 } # The number of wells to create [LEGACY: use well_count instead]
      well_count { sample_count } # The number of wells to create
      well_factory { :well } # The factory to use for wells
      studies { build_list(:study, 1) } # A list of studies to apply to wells.
      projects { build_list(:project, 1) } # A list of projects to apply to wells
      well_order { :column_order } # The order of wells on the plate. Almost always column_order

      # HELPERS: Generally you shouldn't need to use these transients
      studies_cycle { studies.cycle } # Allow us to rotate through listed studies when building out wells
      projects_cycle { projects.cycle } # Allow us to rotate through listed studies when building out wells
      well_locations { maps.where(well_order => occupied_well_index) }
      occupied_well_index { (0...well_count) }
    end

    after(:build) do |plate, evaluator|
      plate.wells =
        evaluator.well_locations.map do |map|
          build(
            evaluator.well_factory,
            map: map,
            study: evaluator.studies_cycle.next,
            project: evaluator.projects_cycle.next
          )
        end
    end
  end

  trait :with_submissions do
    transient do
      submission_count { 1 }
      submissions { create_list(:submission, submission_count) }
      submission_cycle { submissions.cycle }
    end
    after(:create) do |plate, evaluator|
      plate.wells.each do |well|
        well.transfer_requests_as_target << create(
          :transfer_request,
          target_asset: well,
          submission: evaluator.submission_cycle.next
        )
      end
    end
  end

  trait :with_transfers_as_destination do
    transient { transfer_count { 1 } }
    after(:create) do |plate, factory|
      create_list(:transfer_between_plates, factory.transfer_count, destination: plate)
    end
  end

  trait :plate_barcode do
    transient { barcode { nil } }

    # May be a nicer way of doing this?
    sanger_barcode { barcode.nil? ? build(:plate_barcode) : build(:plate_barcode, barcode:) }
  end

  factory :plate, traits: %i[plate_barcode with_wells] do
    plate_purpose
    size { 96 }

    transient { barcode { nil } }

    factory :input_plate do
      plate_purpose factory: %i[input_plate_purpose]
    end

    factory :target_plate do
      transient do
        parent { build(:input_plate) }
        submission { build(:submission) }
      end

      after(:build) do |plate, evaluator|
        well_hash = evaluator.parent.wells.index_by(&:map_description)
        plate.save!
        plate.wells.each do |well|
          well.stock_well_links << build(
            :stock_well_link,
            target_well: well,
            source_well: well_hash[well.map_description]
          )
          outer_request =
            well_hash[well.map_description].requests.detect { |r| r.submission_id == evaluator.submission.id }

          create(
            :transfer_request,
            asset: well_hash[well.map_description],
            target_asset: well,
            outer_request: outer_request
          )
        end
      end
    end

    factory :plate_with_untagged_wells_and_custom_name do
      transient do
        sample_count { 8 }
        well_factory { :untagged_well }
      end
      sequence(:name) { |i| "Plate #{i}" }
    end

    factory :plate_with_untagged_wells do
      transient do
        sample_count { 8 }
        well_factory { :untagged_well }
      end
    end

    factory :plate_with_tagged_wells do
      transient do
        sample_count { 8 }
        well_factory { :tagged_well }
      end

      factory :final_plate do
        transient { well_factory { :passed_well } }
      end
    end

    factory :plate_with_empty_wells do
      transient { well_count { 8 } }
    end

    factory :source_plate do
      plate_purpose { |pp| pp.association(:source_plate_purpose) }
    end

    factory :child_plate do
      transient { parent { create(:source_plate) } }

      plate_purpose { |pp| pp.association(:plate_purpose, source_purpose: parent.purpose) }

      after(:create) do |child_plate, evaluator|
        child_plate.parents << evaluator.parent
        child_plate.purpose.source_purpose = evaluator.parent.purpose
      end
    end

    factory :plate_with_wells_for_specified_studies do
      transient do
        studies { create_list(:study, 2) }
        project { nil }

        occupied_map_locations do
          Map.where_plate_size(size).where_plate_shape(AssetShape.default).where(well_order => (0...studies.size))
        end
        well_order { :column_order }
      end

      after(:create) do |plate, evaluator|
        plate.wells =
          evaluator.occupied_map_locations.map.with_index do |map, i|
            create(:well_for_location_report, map: map, study: evaluator.studies[i], project: nil)
          end
      end
    end

    factory :plate_with_fluidigm_barcode do
      transient do
        sample_count { 8 }
        well_factory { :tagged_well }
      end
      plate_purpose { create(:fluidigm_192_purpose) }
      barcodes { build_list(:fluidigm, 1) }
      size { 192 }
    end
  end

  factory(:full_plate, class: 'Plate', traits: %i[plate_barcode with_wells]) do
    size { 96 }
    plate_purpose

    transient do
      well_count { 96 }
      barcode { nil }
    end

    # A plate that has exactly the right number of wells!
    factory :pooling_plate do
      plate_purpose { create(:pooling_plate_purpose) }
      transient do
        well_count { 6 }
        well_factory { :tagged_well }
      end
    end

    factory :non_stock_pooling_plate do
      plate_purpose

      transient do
        well_count { 6 }
        well_factory { :empty_well }
      end
    end

    factory :input_plate_for_pooling do
      plate_purpose factory: %i[input_plate_purpose]
      transient do
        well_count { 6 }
        well_factory { :tagged_well }
      end
    end

    factory :stock_plate do
      plate_purpose factory: %i[stock_plate_purpose]
    end

    factory(:full_stock_plate) do
      plate_purpose { PlatePurpose.stock_plate_purpose }

      factory(:partial_plate) { transient { well_count { 48 } } }

      factory(:plate_for_strip_tubes) do
        transient do
          well_count { 8 }
          well_factory { :tagged_well }
        end
      end

      factory(:two_column_plate) { transient { well_count { 16 } } }
    end

    factory(:full_plate_with_samples) { transient { well_factory { :tagged_well } } }
  end

  factory :control_plate, class: 'ControlPlate', traits: %i[plate_barcode with_wells] do
    plate_purpose
    name { 'Control Plate name' }
    size { 96 }

    transient { well_factory { :untagged_well } }

    after(:create) do |plate, _evaluator|
      custom_metadatum = CustomMetadatum.new
      custom_metadatum.key = 'control_placement_type'
      custom_metadatum.value = 'random'
      custom_metadatum_collection = CustomMetadatumCollection.new
      custom_metadatum_collection.custom_metadata = [custom_metadatum]
      custom_metadatum_collection.asset = plate
      custom_metadatum_collection.user = User.new(id: 1)
      custom_metadatum_collection.save!
      custom_metadatum.save!

      plate.wells.each_with_index do |well, index|
        next if well.aliquots.empty?

        if index.even?
          well.aliquots.first.sample.update(control: true, control_type: 'positive')
        else
          well.aliquots.first.sample.update(control: true, control_type: 'negative')
        end
      end
    end
  end

  factory :pico_assay_plate, traits: %i[plate_barcode with_wells] do
    plate_purpose
    size { 96 }

    factory :pico_assay_a_plate, traits: %i[plate_barcode with_wells] do
      plate_purpose
      size { 96 }
    end
    factory :pico_assay_b_plate, traits: %i[plate_barcode with_wells] do
      plate_purpose
      size { 96 }
    end
  end
  factory :pico_dilution_plate, traits: %i[plate_barcode with_wells] do
    plate_purpose
    size { 96 }
  end
  factory :sequenom_qc_plate, traits: %i[plate_barcode with_wells] do
    sequence(:name) { |i| "Sequenom #{i}" }
    plate_purpose
    size { 96 }
  end
  factory :working_dilution_plate, traits: %i[plate_barcode with_wells] do
    plate_purpose
    size { 96 }
  end

  # StripTubes are effectively thin plates
  factory :strip_tube do
    name { 'Strip_tube' }
    size { 8 }
    plate_purpose { create(:strip_tube_purpose) }
    after(:create) { |st| st.wells = st.maps.map { |map| create(:well, map:) } }
  end
end
