FactoryGirl.define do
  factory :tag2_layout do
    association(:plate, factory: :plate_with_untagged_wells)
    tag
    user
  end
end
