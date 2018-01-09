# frozen_string_literal: true

FactoryGirl.define do
  factory :container, class: Aker::Container do
    transient do
      sequence(:index) { |n| n }
    end

    barcode { "AKER-#{index}" }

    factory :container_with_address do
      address { "A:#{index}" }
    end
  end
end
