FactoryGirl.define do
  factory :tube do
    name                { generate :asset_name }
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
end
