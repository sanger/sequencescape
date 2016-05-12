FactoryGirl.define do

  factory :column, class: SampleManifestExcel::Column do
    heading "PUBLIC NAME"
    name :public_name
    initialize_with { new(name: name, heading: heading) }

    factory :unlocked_column do
      unlocked :true
      initialize_with { new(name: name, heading: heading, unlocked: true) }

      factory :column_with_validation do
      	validation ({options: {type: :textLength, operator: :lessThanOrEqual, formula1: "20", showErrorMessage: true, errorStyle: :stop, errorTitle: "Supplier Sample Name", error: "Name must be a maximum of 20 characters in length", allowBlank: false}, range_name: :gender})
      	initialize_with { new(name: name, heading: heading, validation: validation) }

      	factory :column_with_validation_and_conditional_formatting do
        	conditional_formatting_rules [{'type' => 'type1', 'operator' => 'operator1', 'dxfId' => :style_name, 'formula' => 'ISERROR(MATCH(first_cell_relative_reference,range_absolute_reference,0)>0)'},{'type' => 'type1', 'operator' => 'operator2', formula: "smth2(first_cell_relative_reference)"}]
      		initialize_with { new(name: name, heading: heading, unlocked: true, validation: validation, conditional_formatting_rules: conditional_formatting_rules) }

        end
    	end
    end

    factory :column_with_position, class: SampleManifestExcel::Column do
      after(:build)  {|column| column.set_number(3).add_reference(10, 15)}
    end
  end

end