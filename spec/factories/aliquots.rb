# frozen_string_literal: true

FactoryBot.define do
  factory :aliquot, aliases: [:tagged_aliquot, :dual_tagged_aliquot] do
    sample
    study
    project
    tag
    tag2
    receptacle

    factory :untagged_aliquot do
      tag  { nil }
      tag2 { nil }
    end

    factory :single_tagged_aliquot do
      tag
      tag2 { nil }
    end

    factory :minimal_aliquot do
      study { nil }
      project { nil }
      tag { nil }
      tag2 { nil }
    end

    factory :library_aliquot do
      library { build :library_tube }
      library_type { 'Standard' }
      bait_library
      primer_panel
      insert_size_from { 100 }
      insert_size_to   { 200 }
    end
  end
end
