FactoryGirl.define do

  factory :validation, class: SampleManifestExcel::Validation do
    options ({option1: 'value1', option2: 'value2', type: :smth, formula1: 'smth'})
    initialize_with { new(options: options) }

    factory :validation_with_range do
  		range_name :some_range
  		initialize_with { new(options: options, range_name: range_name) }
  	end

  end

end