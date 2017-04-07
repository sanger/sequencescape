require 'factory_girl'

FactoryGirl.define do

  factory :tube do
    name { generate :asset_name }
    association(:purpose, factory: :tube_purpose)
  end

  factory :empty_sample_tube, class: SampleTube do
    name                { generate :asset_name }
    value               ''
    descriptors         []
    descriptor_fields   []
    qc_state            ''
    resource            nil
    barcode
    purpose { Tube::Purpose.standard_sample_tube }
  end

  factory :sample_tube, parent: :empty_sample_tube do
    transient do
      sample { create(:sample) }
      study { create(:study) }
      project { create(:project) }
    end

    after(:create) do |sample_tube, evaluator|
      create_list(:untagged_aliquot, 1, sample: evaluator.sample, receptacle: sample_tube, study: evaluator.study, project: evaluator.project)
    end
  end

  factory :qc_tube do
    barcode
  end

  factory :multiplexed_library_tube do
    name    { |_a| generate :asset_name }
    purpose { Tube::Purpose.standard_mx_tube }
  end

  factory :pulldown_multiplexed_library_tube do
    name { |_a| generate :asset_name }
    public_name 'ABC'
  end

  factory :stock_multiplexed_library_tube do
    name    { |_a| generate :asset_name }
    purpose { Tube::Purpose.stock_mx_tube }

    factory :new_stock_multiplexed_library_tube do |_t|
      purpose { |a| a.association(:new_stock_tube_purpose) }
    end
  end

  factory(:empty_library_tube, class: LibraryTube) do
    qc_state ''
    name     { |_| generate :asset_name }
    purpose  { Tube::Purpose.standard_library_tube }
  end

  factory(:library_tube, parent: :empty_library_tube) do
    transient do
      sample { create :sample }
      library_type 'Standard'
    end

    after(:create) do |library_tube, evaluator|
      library_tube.aliquots << build(:untagged_aliquot, sample: evaluator.sample, library_type: evaluator.library_type, receptacle: library_tube)
    end
  end

  factory(:tagged_library_tube, class: LibraryTube) do
    transient do
      tag_map_id 1
    end

    after(:create) do |library_tube, evaluator|
      library_tube.aliquots << build(:tagged_aliquot, tag: create(:tag, map_id: evaluator.tag_map_id), receptacle: library_tube)
    end
  end

  factory :pac_bio_library_tube do
    transient do
      aliquot { build(:tagged_aliquot) }
    end
    barcode
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
      tube.parents << (1..5).map { |_| create(:multiplexed_library_creation_request).target_asset }
    end
  end

  factory :broken_multiplexed_library_tube, parent: :multiplexed_library_tube

  factory :stock_library_tube do
    name     { |_a| generate :asset_name }
    purpose  { Tube::Purpose.stock_library_tube }
  end

  factory :stock_sample_tube do
    name     { |_a| generate :asset_name }
    purpose  { Tube::Purpose.stock_sample_tube }
  end
end
