# frozen_string_literal: true

FactoryBot.define do
  factory :sample do
    name { generate :sample_name }

    factory :sample_with_well do
      sequence(:sanger_sample_id, &:to_s)
      wells { [FactoryBot.create(:well_with_sample_and_plate)] }
      assets { [wells.first.plate] }
    end

    factory :sample_with_gender do
      association :sample_metadata, factory: :sample_metadata_with_gender
    end

    factory :sample_with_sanger_sample_id do
      sequence(:sanger_sample_id, &:to_s)
    end
  end

  factory :study_sample do
    study
    sample
  end
end
