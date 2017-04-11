FactoryGirl.define do
  factory :range_list, class: SampleManifestExcel::RangeList do
    options { { a: ['option1', 'option2'], b: ['option3', 'option4'], c: ['option5', 'option6'] } }

    initialize_with { new(options) }
    skip_create
  end
end
