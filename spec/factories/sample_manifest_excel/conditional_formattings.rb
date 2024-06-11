# frozen_string_literal: true

FactoryBot.define do
  factory :conditional_formatting, class: 'SequencescapeExcel::ConditionalFormatting' do
    options { { 'option1' => 'value1', 'option2' => 'value2', 'formula' => 'some_formula' } }
    style { { bg_color: '82CAFA', type: :dxf } }

    initialize_with { new(options:, style:) }

    factory :conditional_formatting_with_formula, class: 'SequencescapeExcel::ConditionalFormatting' do
      formula { { type: :len, operator: '>', operand: 10 } }
      initialize_with { new(options:, style:, formula:) }
    end

    skip_create
  end
end
