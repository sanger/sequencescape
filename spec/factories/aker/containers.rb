# frozen_string_literal: true

FactoryGirl.define do
  factory :container, class: Aker::Container do
    transient do
      sequence(:index) { |n| n }
    end

    barcode { "AKER-#{index}" }
  end

  factory :container_with_address, class: Aker::Container do
    barcode { 'AKER-1' }
    address { 'A:1' }
  end
end
