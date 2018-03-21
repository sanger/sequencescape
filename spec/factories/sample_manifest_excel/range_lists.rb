# frozen_string_literal: true

FactoryGirl.define do
  factory :range_list, class: SampleManifestExcel::RangeList do
    ranges_data { { a: { options: %w[option1 option2] }, b: { options: %w[option3 option4] }, c: { options: %w[option5 option6] } } }

    initialize_with { new(ranges_data) }

    skip_create
  end
end
