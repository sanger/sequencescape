FactoryGirl.define do
  factory :range, class: SampleManifestExcel::Range do
    options ['option1', 'option2', 'option3']
    first_row 1
    worksheet_name 'Sheet1'

    initialize_with { new(options: options, first_row: first_row, worksheet_name: worksheet_name) }

    skip_create
  end
end
