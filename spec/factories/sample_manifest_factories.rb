# frozen_string_literal: true

FactoryBot.define do
  factory :sample_manifest do
    study
    supplier
    asset_type 'plate'
    count 1

    factory :sample_manifest_with_samples do
      samples { FactoryBot.create_list(:sample_with_well, 5) }
    end

    factory :tube_sample_manifest do
      asset_type '1dtube'

      factory :tube_sample_manifest_with_samples do
        samples { FactoryBot.create_list(:sample_tube, 5).map(&:samples).flatten }
      end
      factory :tube_sample_manifest_with_several_tubes do
        count 5
      end
    end

    factory :sample_manifest_with_samples_for_plates do
      transient do
        num_plates 2
        num_samples_per_plate 2
      end

      samples { FactoryBot.create_list(:plate_with_untagged_wells, num_plates, sample_count: num_samples_per_plate).map(&:contained_samples).flatten }

      # set sanger_sample_id on samples
      after(:build) do |sample_manifest|
        sample_manifest.samples.each do |smpl|
          smpl.sanger_sample_id = "test_#{smpl.id}"
          smpl.save
        end
      end
    end
  end

  factory :supplier do
    name 'Test supplier'
  end
end
