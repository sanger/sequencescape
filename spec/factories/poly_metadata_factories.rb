# frozen_string_literal: true

FactoryBot.define do
  factory :poly_metadatum do
    sequence(:key) { |n| "some_key_#{n}" }
    sequence(:value) { |n| "some_value_#{n}" }

    metadatable { create(:request) }

    factory :plate_poly_metadatum do
      metadatable { create(:plate) }

      # override the metadatable_type otherwise you get class.polymprophic_name which is
      # not the same as class.name and will cause problems in lookup
      after(:build) do |pm|
        pm.metadatable_type = pm.metadatable.class.name
      end
    end

    factory :well_poly_metadatum do
      metadatable { create(:well) }

      # override the metadatable_type otherwise you get class.polymprophic_name which is
      # not the same as class.name and will cause problems in lookup
      after(:build) do |pm|
        pm.metadatable_type = pm.metadatable.class.name
      end
    end
  end
end
