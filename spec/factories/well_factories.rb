# frozen_string_literal: true

FactoryBot.define do
  factory :well, aliases: [:empty_well] do
    transient do
      study { build(:study) }
      project { build(:project) }
      sample { build(:sample) }
      aliquot_options { |_e, well| { study:, project:, receptacle: well, sample: } }
    end
    association(:well_attribute, strategy: :build)

    factory :untagged_well, parent: :well do
      aliquots { build_list(:untagged_aliquot, 1, aliquot_options) }
    end

    factory :picked_well do
      well_attribute { build(:well_attribute, picked_volume: 12) }
    end
  end

  factory :well_attribute do
    concentration { 23.2 }
    current_volume { 15 }

    factory :complete_well_attribute do
      gel_pass { 'Pass' }
      pico_pass { 'Pass' }
      sequenom_count { 2 }
    end
  end

  factory :tagged_well, parent: :well, aliases: [:well_with_sample_and_without_plate] do
    transient { aliquot_count { 1 } }
    aliquots { build_list(:tagged_aliquot, aliquot_count, aliquot_options) }

    factory :passed_well do
      transient do
        aliquot_options do |_e, well|
          { study:, project:, receptacle: well, sample:, request: requests_as_target.first }
        end
      end
      stock_wells { [association(:well)] }
      requests_as_target { [association(:well_request, state: 'passed', asset: stock_wells.first)] }
      transfer_requests_as_target do
        [association(:transfer_request, state: 'passed', submission: requests_as_target.first.submission)]
      end
    end
  end

  factory :well_with_sample_and_plate, parent: :tagged_well do
    map
    plate
  end

  factory :cross_pooled_well, parent: :well do
    map
    plate
    after(:build) do |well|
      als =
        Array.new(2) do
          { sample: create(:sample), study: create(:study), project: create(:project), tag: create(:tag) }
        end
      well.aliquots.build(als)
    end
  end

  factory :well_link, class: 'Well::Link' do
    source_well factory: %i[well]
    target_well factory: %i[well]
    type { 'stock' }

    factory :stock_well_link
  end

  factory :well_for_qc_report, parent: :well do
    samples { [create(:study_sample, study:).sample] }
    plate { create(:plate) }
    map { create(:map) }

    after(:create) { |well, evaluator| well.aliquots.each { |a| a.update!(study: evaluator.study) } }
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
