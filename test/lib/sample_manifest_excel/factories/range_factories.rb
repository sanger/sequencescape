FactoryGirl.define do

  factory :range, class: SampleManifestExcel::Range do
    options ['option1', 'option2', 'option3']
    row 1

    initialize_with { new(options, row) }
  end

end