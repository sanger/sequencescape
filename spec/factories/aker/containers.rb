# frozen_string_literal: true

FactoryGirl.define do
  factory :container, class: Aker::Container do
    transient do
      sequence(:index) { |n| n }
    end

    barcode { "AKER-#{index}" }
  end
end
