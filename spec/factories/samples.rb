# frozen_string_literal: true

FactoryBot.define do
  factory :sample do
    name { generate(:sample_name) }

    # Accessioning is triggered on sample saving, unless processing_manifest is true
    before(:create) { Sample::Current.processing_manifest = true }

    factory :sample_with_well do
      sequence(:sanger_sample_id, &:to_s)

      after(:build) { |sample, _evaluator| sample.wells = create_list(:well_with_sample_and_plate, 1, sample:) }
    end

    factory :sample_with_gender do
      sample_metadata factory: %i[sample_metadata_with_gender]
    end

    factory :sample_with_sanger_sample_id do
      updated_by_manifest { true }
      sequence(:sanger_sample_id, &:to_s)
    end

    factory :accessioned_sample do
      sample_metadata factory: %i[sample_metadata_with_accession_number]
    end
  end

  factory :study_sample do
    study
    sample
  end
end
