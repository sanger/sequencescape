FactoryGirl.define do
  factory :validation, class: SampleManifestExcel::Validation do
    options ({ option1: 'value1', option2: 'value2', type: :none, formula1: 'smth' })
    range_name :some_range

    initialize_with { new(options: options) }

    skip_create
  end
end
