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

    factory :sanger_plate_id_column do

      name      { :sanger_plate_id }
      heading   { "SANGER PLATE ID" }
      value     { number }
      attribute { :barcode }

    end

    factory :sanger_tube_id_column do

      name      { :sanger_tube_id }
      heading   { "SANGER TUBE ID" }
      value     { number }
      attribute { :barcode }

    end

    factory :well_column do

      name      { :well }
      heading   { "WELL" }
      value     { number }
      attribute { :position }
    end

  end

end