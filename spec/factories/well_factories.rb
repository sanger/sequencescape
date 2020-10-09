# frozen_string_literal: true

FactoryBot.define do
  factory :well, aliases: [:empty_well] do
    transient do
      study { build :study }
      project { build :project }
      sample { build :sample }
      aliquot_options { |_e, well| { study: study, project: project, receptacle: well, sample: sample } }
    end
    association(:well_attribute, strategy: :build)

    factory :untagged_well, parent: :well do
      aliquots { build_list(:untagged_aliquot, 1, aliquot_options) }
    end

    factory :picked_well do
      well_attribute { build :well_attribute, picked_volume: 12 }
    end
  end

  factory :well_attribute do
    concentration       { 23.2 }
    current_volume      { 15 }

    factory :complete_well_attribute do
      gel_pass            { 'Pass' }
      pico_pass           { 'Pass' }
      sequenom_count      { 2 }
    end
  end

  factory :tagged_well, parent: :well, aliases: [:well_with_sample_and_without_plate] do
    transient do
      aliquot_count { 1 }
    end
    aliquots { build_list(:tagged_aliquot, aliquot_count, aliquot_options) }
  end

  factory :well_with_sample_and_plate, parent: :tagged_well do
    map
    plate
  end

  factory :cross_pooled_well, parent: :well do
    map
    plate
    after(:build) do |well|
      als = Array.new(2) do
        {
          sample: create(:sample),
          study: create(:study),
          project: create(:project),
          tag: create(:tag)
        }
      end
      well.aliquots.build(als)
    end
  end

  factory :well_link, class: 'Well::Link' do
    association(:source_well, factory: :well)
    association(:target_well, factory: :well)
    type { 'stock' }

    factory :stock_well_link
  end

  factory :well_for_qc_report, parent: :well do
    samples { [create(:study_sample, study: study).sample] }
    plate { create(:plate) }
    map { create(:map) }

    after(:create) do |well, evaluator|
      well.aliquots.each { |a| a.update!(study: evaluator.study) }
    end
  end

  factory :well_for_location_report, parent: :well do
    transient do
      study
      project
    end

    after(:create) do |well, evaluator|
      well.aliquots << build(:untagged_aliquot, receptacle: well, study: evaluator.study, project: evaluator.project)
    end
  end
end
