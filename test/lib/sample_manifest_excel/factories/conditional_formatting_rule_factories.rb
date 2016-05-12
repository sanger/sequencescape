FactoryGirl.define do

  factory :complicated_conditional_formatting_rule, class: SampleManifestExcel::ConditionalFormattingRule do
  	options ({'option1' => 'value1', 'option2' => 'value2', 'dxfId' => :style_name, 'formula' => 'ISERROR(MATCH(first_cell_relative_reference,range_absolute_reference,0)>0)'})
  	initialize_with { new(options) }
  end

  factory :simple_conditional_formatting_rule, class: SampleManifestExcel::ConditionalFormattingRule do
  	options ({'option1' => 'value1', 'option2' => 'value2', 'formula' => 'some_formula'})
  	initialize_with { new(options) }
  end

end