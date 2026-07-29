# frozen_string_literal: true

FactoryBot.define do
  factory :compound_aliquot do
    source_aliquots { [build(:tagged_aliquot, tag_depth: 1), build(:tagged_aliquot, tag_depth: 2)] }
    request { nil }

    initialize_with do
      CompoundAliquot.new(
        source_aliquots:,
        request:
      )
    end

    to_create { |instance| }
  end
end
