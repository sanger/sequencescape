# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_transfer do
    user
    transfers { create_list(:transfer_between_plates, 3) }
  end
end
