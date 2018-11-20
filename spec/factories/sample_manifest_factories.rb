# frozen_string_literal: true

FactoryBot.define do
  factory :sample_manifest do
    study
    supplier
    asset_type { 'plate' }
    count { 1 }

    factory :sample_manifest_with_samples do
      samples { FactoryBot.create_list(:sample_with_well, 5) }
    end

    factory :sample_manifest_with_empty_plate do
      transient do
        well_count { 96 }
        plate_count { 1 }
      end
      labware { FactoryBot.create_list(:plate_with_empty_wells, plate_count, well_count: well_count) }
    end

    factory :tube_sample_manifest do
      asset_type { '1dtube' }

      factory :tube_sample_manifest_with_samples do
        samples { FactoryBot.create_list(:sample_tube, 5).map(&:samples).flatten }

        factory :tube_sample_manifest_with_tubes do
          count { 5 }

          after(:build) do |sample_manifest|
            sample_manifest.barcodes = sample_manifest.labware.map(&:human_barcode)
          end
        end
      end
    end

    factory :sample_manifest_with_samples_for_plates do
      transient do
        num_plates { 2 }
        num_samples_per_plate { 2 }
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
    name { 'Test supplier' }
  end
end
