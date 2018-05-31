# frozen_string_literal: true

FactoryBot.define do
  factory :container, class: Aker::Container do
    transient do
      sequence(:index) { |n| n }
    end

    barcode { "AKER-#{index}" }
  end

  factory :container_with_address, class: Aker::Container do
    transient do
      sequence(:index) { |n| n }
      sequence(:address_for_aker) { |value|
        quotient, remainder = value.divmod(12)
        "#{('A'..'Z').to_a[quotient % 8]}:#{(remainder % 12)+1}" 
      }      
    end

    barcode { 'AKER-1' }
    address { address_for_aker }
  end
end
