FactoryGirl.define do
  factory :purpose_relationship, class: Purpose::Relationship do
    association :parent, factory: :purpose
    association :child, factory: :purpose
    association :transfer_request_type, factory: :request_type
  end
end
