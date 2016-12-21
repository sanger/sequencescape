FactoryGirl.define do
  factory :plate_barcode do
    sequence(:barcode) { |i| i }
  end
end