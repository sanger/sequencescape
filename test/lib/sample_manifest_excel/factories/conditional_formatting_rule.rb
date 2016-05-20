FactoryGirl.define do

  factory :conditional_formatting_rule, class: SampleManifestExcel::ConditionalFormattingRule do

    options ({'option1' => 'value1', 'option2' => 'value2', 'formula' => 'some_formula'})
    initialize_with { new(options: options) }

    factory :conditional_formatting_rule_with_style_and_complex_formula, class: SampleManifestExcel::ConditionalFormattingRule do

      style :style_name
      formula { {type: :len, operator: ">", operand: 10} }
      options ({'option1' => 'value1', 'option2' => 'value2'})
      initialize_with { new(style: style, formula: formula, options: options) }
    end

  end

end