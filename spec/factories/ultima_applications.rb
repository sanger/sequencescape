# frozen_string_literal: true

FactoryBot.define do
  factory :ultima_preset do
    sequence(:name) { |i| "Preset #{i}" }
    sequence(:application_type) { |i| "application_type_#{i}" }
    sequence(:sequencing_recipe) { |i| "#{i + 1} cycles" }
  end

  factory :ultima_primer do
    sequence(:name) { |i| "Primer #{i}" }
  end

  factory :ultima_application do
    sequence(:name) { |i| "Application #{i}" }
    sequence(:description) { |i| "Ultima application #{i}" }
    ug100_preset factory: :ultima_preset
    ug200_preset factory: :ultima_preset
    uga_primer factory: :ultima_primer
    ugb_primer factory: :ultima_primer
  end
end
