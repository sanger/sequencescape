FactoryGirl.define do

  factory :range_list, class: SampleManifestExcel::RangeList do

    ranges_data { { a: {options: ["option1", "option2"]}, b: {options: ["option3", "option4"]}, c: {options: ["option5", "option6"]} } }

    initialize_with { new(ranges_data) }

  end

end