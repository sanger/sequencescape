# frozen_string_literal: true

require 'factory_bot'

FactoryBot.define do
  trait :scanned_into_lab do
    after(:create) { |asset, _evaluator| asset.create_scanned_into_lab_event!(content: '2018-01-01') }
  end

  trait :tube_barcode do
    transient do
      barcode_number { barcode }
      barcode { generate :barcode_number }
      prefix { 'NT' }
    end
    sanger_barcode { { prefix:, number: barcode_number } }
  end

  trait :in_a_rack do
    transient do
      tube_rack { nil }
      coordinate { nil }
    end
    after(:create) do |tube, evaluator|
      create(:racked_tube, tube:, tube_rack: evaluator.tube_rack, coordinate: evaluator.coordinate)
    end
  end

  factory :tube, traits: [:tube_barcode] do
    name { generate :asset_name }
    purpose factory: %i[tube_purpose]
  end

  factory :unbarcoded_tube, class: 'Tube' do
    name { generate :asset_name }
    purpose factory: %i[tube_purpose]
  end

  factory :empty_sample_tube, class: 'SampleTube', traits: [:tube_barcode] do
    name { generate :asset_name }
    qc_state { '' }
    purpose factory: %i[sample_tube_purpose] # { Tube::Purpose.standard_sample_tube }
  end

  factory :sample_tube, parent: :empty_sample_tube do
    transient do
      sample_factory { :sample }
      sample { create(sample_factory, sample_attributes) }
      study { create(:study) }
      project { create(:project) }
      sample_attributes { {} }
    end

    after(:create) do |sample_tube, evaluator|
      next unless sample_tube.aliquots.empty?

      sample_tube.aliquots =
        create_list(
          :untagged_aliquot,
          1,
          sample: evaluator.sample,
          receptacle: sample_tube,
          study: evaluator.study,
          project: evaluator.project
        )
    end

    factory :sample_tube_with_sanger_sample_id do
      transient { sample { create(:sample_with_sanger_sample_id) } }
    end
  end

  factory :qc_tube, traits: [:tube_barcode]

  factory :multiplexed_library_tube, traits: [:tube_barcode] do
    transient do
      sample_count { 0 }
      study { create(:study) }
    end

    name { generate :asset_name }
    purpose factory: %i[mx_tube_purpose]
    after(:build) do |tube, evaluator|
      unless evaluator.sample_count.zero?
        tube.aliquots = build_list(:library_aliquot, evaluator.sample_count, study: evaluator.study)
      end
    end
  end

  factory :pulldown_multiplexed_library_tube, traits: [:tube_barcode] do
    name { generate :asset_name }
    public_name { 'ABC' }
  end

  factory :stock_multiplexed_library_tube, traits: [:tube_barcode] do
    name { |_a| generate :asset_name }
    purpose { Tube::Purpose.stock_mx_tube }

    factory :new_stock_multiplexed_library_tube do |_t|
      purpose factory: %i[new_stock_tube_purpose]
    end
  end

  factory(:empty_library_tube, traits: [:tube_barcode], class: 'LibraryTube') do
    name { generate :asset_name }
    purpose factory: %i[library_tube_purpose] #  { Tube::Purpose.standard_library_tube }

    transient do
      sample_count { 0 }
      samples { create_list(:sample, sample_count) }
      aliquot_factory { :untagged_aliquot }
      study { build :study }
    end

    after(:build) do |library_tube, evaluator|
      next if evaluator.sample_count.zero?

      library_tube.aliquots =
        evaluator.samples.map do |s|
          create(
            evaluator.aliquot_factory,
            sample: s,
            library_type: 'Standard',
            receptacle: library_tube,
            library: library_tube,
            study: evaluator.study
          )
        end
    end

    factory(:library_tube) { transient { sample_count { 1 } } }

    factory(:library_tube_with_barcode) do
      after(:build) do |library_tube|
        library_tube.receptacle.aliquots.build(
          sample: create(:sample_with_sanger_sample_id),
          library_type: 'Standard',
          library: library_tube
        )
      end
    end
  end

  factory(:tagged_library_tube, class: 'LibraryTube', traits: [:tube_barcode]) do
    transient do
      tag_map_id { 1 }
      tag { build(:tag, map_id: tag_map_id) }
      sample { create(:sample_with_sanger_sample_id) }
    end

    after(:build) do |library_tube, evaluator|
      library_tube.receptacle.aliquots << build(
        :tagged_aliquot,
        tag: evaluator.tag,
        receptacle: library_tube,
        sample: evaluator.sample,
        library: library_tube
      )
    end
  end

  factory :pac_bio_library_tube, traits: [:tube_barcode] do
    transient do
      aliquot { build(:tagged_aliquot) }
      prep_kit_barcode { 999 }
      smrt_cells_available { 1 }
    end
    pac_bio_library_tube_metadata_attributes { { prep_kit_barcode:, smrt_cells_available: } }
    after(:build) { |t, evaluator| t.receptacle.aliquots << evaluator.aliquot }
  end

  # A library tube is created from a sample tube through a library creation request!
  factory(:full_library_tube, parent: :library_tube) do
    after(:create) { |tube| create(:library_creation_request, target_asset: tube) }
  end

  factory :stock_library_tube do
    name { |_a| generate :asset_name }
    purpose { Tube::Purpose.stock_library_tube }
  end

  factory :spiked_buffer do
    transient do
      tag_option { 'Single' } # The PhiX Tag option to use, eg. Single/Dual
      aliquot_attributes { { tag_option: } }
    end

    name { generate :asset_name }
    concentration { 12.0 }
    volume { 50 }

    after(:build) do |tube, evaluator|
      tube.receptacle.aliquots << build(:phi_x_aliquot, evaluator.aliquot_attributes.merge(library: tube))
    end

    factory :spiked_buffer_with_parent do
      transient { parent { create :spiked_buffer, :tube_barcode } }

      after(:build) { |tube, evaluator| tube.parents << evaluator.parent }
    end
  end

  factory :phi_x_stock_tube, class: 'LibraryTube', traits: [:tube_barcode] do
    transient do
      tag_option { 'Single' } # The PhiX Tag option to use, eg. Single/Dual
      study { create :study }
    end

    name { generate :asset_name }
    concentration { 12.0 }

    after(:build) do |tube, evaluator|
      tube.receptacle.aliquots << build(
        :phi_x_aliquot,
        library: tube,
        tag_option: evaluator.tag_option,
        study: evaluator.study
      )
    end
  end
end
