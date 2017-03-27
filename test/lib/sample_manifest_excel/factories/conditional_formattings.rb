FactoryGirl.define do
  factory :conditional_formatting, class: SampleManifestExcel::ConditionalFormatting do
    options('option1' => 'value1', 'option2' => 'value2', 'formula' => 'some_formula')
    style(bg_color: '82CAFA', type: :dxf)

    initialize_with { new(options: options, style: style) }

    factory :conditional_formatting_with_formula, class: SampleManifestExcel::ConditionalFormatting do
      formula ({ type: :len, operator: '>', operand: 10 })
      initialize_with { new(options: options, style: style, formula: formula) }
    end

    skip_create
  end
end
