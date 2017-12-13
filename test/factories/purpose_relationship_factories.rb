FactoryGirl.define do
  factory :purpose_relationship, class: Purpose::Relationship do
    association :parent, factory: :purpose
    association :child, factory: :purpose
    transfer_request_class_name :standard
  end
end
