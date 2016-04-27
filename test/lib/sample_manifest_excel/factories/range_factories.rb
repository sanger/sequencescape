FactoryGirl.define do

  factory :range, class: SampleManifestExcel::Range do
    options ['option1', 'option2', 'option3']
    row 1

    initialize_with { new(options, row) }

    factory :range_with_absolute_reference do
    	after(:build)  do |range|
    		worksheet = build :worksheet
    		range.set_absolute_reference(worksheet)
    	end
    end
  end

end