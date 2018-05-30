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
  end

  factory :supplier do
    name 'Test supplier'
  end
end
