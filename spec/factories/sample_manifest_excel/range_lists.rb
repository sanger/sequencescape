# frozen_string_literal: true

FactoryBot.define do
  factory :range_list, class: 'SequencescapeExcel::RangeList' do
    ranges_data do
      { a: { options: %w[option1 option2] }, b: { options: %w[option3 option4] }, c: { options: %w[option5 option6] } }
    end

    initialize_with { new(ranges_data) }

    skip_create
  end
end
