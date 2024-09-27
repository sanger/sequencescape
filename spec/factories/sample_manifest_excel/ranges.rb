# frozen_string_literal: true

FactoryBot.define do
  factory :range, class: 'SequencescapeExcel::Range' do
    options { %w[option1 option2 option3] }
    first_row { 1 }
    worksheet_name { 'Sheet1' }

    initialize_with { new(options:, first_row:, worksheet_name:) }

    skip_create
  end
end
