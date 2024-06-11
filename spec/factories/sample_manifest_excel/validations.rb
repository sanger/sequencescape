# frozen_string_literal: true

FactoryBot.define do
  factory :validation, class: 'SequencescapeExcel::Validation' do
    options { { option1: 'value1', option2: 'value2', type: :none, formula1: 'smth' } }
    range_name { :some_range }

    initialize_with { new(options:) }

    skip_create
  end
end
