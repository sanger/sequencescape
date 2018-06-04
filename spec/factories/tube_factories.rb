# frozen_string_literal: true

require 'factory_bot'

FactoryBot.define do
  trait :scanned_into_lab do
    after(:build) do |asset, _evaluator|
      asset.create_scanned_into_lab_event!(content: '2018-01-01')
    end
  end

  trait :tube_barcode do
    transient do
      barcode_number { barcode }
      barcode { generate :barcode_number }
      prefix 'NT'
    end
    sanger_barcode { { prefix: prefix, number: barcode_number } }
  end

  factory :tube, traits: [:tube_barcode] do
    name { generate :asset_name }
    association(:purpose, factory: :tube_purpose)
  end

  factory :unbarcoded_tube, class: Tube do
    name { generate :asset_name }
    association(:purpose, factory: :tube_purpose)
  end

  factory :empty_sample_tube, class: SampleTube, traits: [:tube_barcode] do
    name                { generate :asset_name }
    value               ''
    descriptors         []
    descriptor_fields   []
    qc_state            ''
    association(:purpose, factory: :sample_tube_purpose) # { Tube::Purpose.standard_sample_tube }
  end

  factory :sample_tube, parent: :empty_sample_tube do
    transient do
      sample { create(:sample) }
      study { create(:study) }
      project { create(:project) }
    end

    after(:create) do |sample_tube, evaluator|
      sample_tube.aliquots = create_list(:untagged_aliquot, 1, sample: evaluator.sample, receptacle: sample_tube, study: evaluator.study, project: evaluator.project)
    end

    factory :sample_tube_with_sanger_sample_id do
      transient do
        sample { create(:sample_with_sanger_sample_id) }
      end
    end
  end

  factory :qc_tube, traits: [:tube_barcode]

  factory :multiplexed_library_tube, traits: [:tube_barcode] do
    name { generate :asset_name }
    association(:purpose, factory: :mx_tube_purpose) # { Tube::Purpose.standard_mx_tube }
  end

  factory :pulldown_multiplexed_library_tube, traits: [:tube_barcode] do
    name { generate :asset_name }
    public_name 'ABC'
  end

  factory :stock_multiplexed_library_tube, traits: [:tube_barcode] do
    name    { |_a| generate :asset_name }
    purpose { Tube::Purpose.stock_mx_tube }

    factory :new_stock_multiplexed_library_tube do |_t|
      association(:purpose, factory: :new_stock_tube_purpose)
    end
  end

  factory(:empty_library_tube, traits: [:tube_barcode], class: LibraryTube) do
    name { generate :asset_name }
    association(:purpose, factory: :library_tube_purpose) #  { Tube::Purpose.standard_library_tube }

    transient do
      sample_count 0
      samples { create_list(:sample, sample_count) }
      aliquot_factory { :untagged_aliquot }
    end

    after(:build) do |library_tube, evaluator|
      next if evaluator.sample_count.zero?
      library_tube.aliquots = evaluator.samples.map { |s| create(evaluator.aliquot_factory, sample: s, library_type: 'Standard', receptacle: library_tube) }
    end

    factory(:library_tube) do
      transient { sample_count 1 }
    end

    factory(:library_tube_with_barcode) do
      sequence(:barcode) { |i| i }
      after(:create) do |library_tube|
        library_tube.aliquots.create!(sample: create(:sample_with_sanger_sample_id), library_type: 'Standard', library_id: library_tube.id)
      end
    end
  end

  factory(:tagged_library_tube, class: LibraryTube, traits: [:tube_barcode]) do
    transient do
      tag_map_id 1
    end

    after(:create) do |library_tube, evaluator|
      library_tube.aliquots << build(:tagged_aliquot, tag: create(:tag, map_id: evaluator.tag_map_id), receptacle: library_tube)
    end
  end

  factory :pac_bio_library_tube, traits: [:tube_barcode] do
    transient do
      aliquot { build(:tagged_aliquot) }
      prep_kit_barcode 999
      smrt_cells_available 1
    end
    pac_bio_library_tube_metadata_attributes do
      {
        prep_kit_barcode: prep_kit_barcode,
        smrt_cells_available: smrt_cells_available
      }
    end
    after(:build) do |t, evaluator|
      t.aliquots << evaluator.aliquot
    end
  end

  # A library tube is created from a sample tube through a library creation request!
  factory(:full_library_tube, parent: :library_tube) do
    after(:create) { |tube| create(:library_creation_request, target_asset: tube) }
  end

  # A Multiplexed library tube comes from several library tubes, which are themselves created through a
  # number of multiplexed library creation requests.  But the binding to these tubes comes from the parent-child
  # relationships.
  factory :full_multiplexed_library_tube, parent: :multiplexed_library_tube do
    after(:create) do |tube|
      tube.parents << Array.new(5) { create(:multiplexed_library_creation_request, target_asset: tube).asset }
    end
  end

  factory :broken_multiplexed_library_tube, parent: :multiplexed_library_tube

  factory :stock_library_tube do
    name     { |_a| generate :asset_name }
    purpose  { Tube::Purpose.stock_library_tube }
  end
end
