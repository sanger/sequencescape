FactoryGirl.define do

  factory :column, class: SampleManifestExcel::Column do
    heading "PUBLIC NAME"
    name :public_name
    initialize_with { new(name: name, heading: heading) }

    factory :column_with_validation do
    	validation ({options: {type: :textLength, operator: :lessThanOrEqual, formula1: "20", showErrorMessage: true, errorStyle: :stop, errorTitle: "Supplier Sample Name", error: "Name must be a maximum of 20 characters in length", allowBlank: false}, range_name: :some_name})
    	initialize_with { new(name: name, heading: heading, validation: validation) }

    	factory :column_with_validation_and_cf do
      	conditional_formatting_rules [{'type' => 'type1', 'operator' => 'operator1', 'dxfId' => :style_name, 'formula' => 'ISERROR(MATCH(first_cell_relative_reference,range_absolute_reference,0)>0)'},{'type' => 'type1', 'operator' => 'operator2', formula: "smth2(first_cell_relative_reference)"}]
    		initialize_with { new(name: name, heading: heading, validation: validation, conditional_formatting_rules: conditional_formatting_rules) }

    	end
    end
  end

end