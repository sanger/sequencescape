# frozen_string_literal: true

FactoryBot.define do
  factory :sample do
    name { generate(:sample_name) }

    # Accessioning is triggered on sample saving, unless temporary_accessioning_pause is true
    before(:create) { Sample::Current.temporary_accessioning_pause = true }

    factory :sample_with_well do
      sanger_sample_id { generate(:sanger_sample_id) }

      after(:build) { |sample, _evaluator| sample.wells = create_list(:well_with_sample_and_plate, 1, sample:) }
    end

    factory :sample_with_gender do
      sample_metadata factory: %i[sample_metadata_with_gender]
    end

    factory :sample_with_sanger_sample_id do
      updated_by_manifest { true }
      sanger_sample_id { generate(:sanger_sample_id) }
    end

    factory :sample_with_accession_number do
      sample_metadata factory: %i[sample_metadata_with_accession_number]
    end
  end

  factory :study_sample do
    study
    sample
  end
end
FactoryBot.define do
  factory :sample_compound_component do
    compound_sample factory: :sample
    component_sample factory: :sample
  end
end
