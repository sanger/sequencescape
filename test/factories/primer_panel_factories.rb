FactoryGirl.define do
  factory :primer_panel do
    sequence(:name) { |i| "Primer Panel #{i}" }
    snp_count 1
  end
end
