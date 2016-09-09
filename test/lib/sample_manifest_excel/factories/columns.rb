FactoryGirl.define do

  factory :column, class: SampleManifestExcel::Column do
    sequence(:number)   { |n| n }
    name                { "column_#{number}".to_sym } 
    heading             { "Column #{number}" }
    value               { "Value #{number}"}

    initialize_with { new(name: name, heading: heading, number: number, value: value) }

    factory :sanger_sample_id_column do

      name              { :sanger_sample_id }
      heading           { "SANGER SAMPLE ID" }
      value             { number }
      attribute         { :sample_id }

    end

  end

end