FactoryGirl.define do
  factory :container, class: Aker::Container do
    sequence(:barcode) { |n| "AKER-#{n}" }
  end
end
