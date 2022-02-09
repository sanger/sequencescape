# frozen_string_literal: true

FactoryBot.define do


  factory :insdc_country, class: 'Insdc::Country' do
    sequence(:name) { |i| "Country #{i}"}

    trait :high_priority do
      sort_priority { 2 }
    end

    trait :valid do
      validation_state { :valid }
    end

    trait :invalid do
      validation_state { :invalid }
    end
  end
end
