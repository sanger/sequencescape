FactoryGirl.define do

  factory :column, class: SampleManifestExcel::Column do
    sequence(:number)   { |n| n }
    name                { "column_#{number}".to_sym } 
    heading             { "Column #{number}" }

    initialize_with { new(name: name, heading: heading, number: number) }

  end

end