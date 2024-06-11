# frozen_string_literal: true

FactoryBot.define do
  factory :aliquot, aliases: %i[tagged_aliquot dual_tagged_aliquot] do
    sample
    study
    project
    tag
    tag2
    receptacle

    factory :untagged_aliquot do
      tag { nil }
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
      library { build(:library_tube) }
      library_type { 'Standard' }
      bait_library
      primer_panel
      insert_size_from { 100 }
      insert_size_to { 200 }
    end

    factory :phi_x_aliquot do
      transient do
        tag_option { 'Single' } # The PhiX Tag option to use
      end

      sample { PhiX.sample }
      library { build(:library_tube) }
      tag { PhiX.find_tag(tag_option, :i7_oligo) }
      tag2 { PhiX.find_tag(tag_option, :i5_oligo) }
      study { nil }
      project { nil }
    end
  end
end
