FactoryGirl.define do
  factory :primer_set do
    sequence(:name) { |i| "Primer Set #{i}" }
    snp_count 1
  end
end
