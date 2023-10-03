# frozen_string_literal: true

FactoryBot.define do
  factory :transfer_request do
    asset factory: %i[well]
    target_asset factory: %i[well]

    factory :transfer_request_with_submission do
      submission factory: %i[submission]

      factory :transfer_request_with_volume do
        volume { 10 }
      end
    end
  end
end
