# frozen_string_literal: true

FactoryBot.define do

  factory :tag_set do
    transient do
      adapter_type { build(:adapter_type) }
    end

    sequence(:name) { |n| "Tag Set #{n}" }
    tag_group { create(:tag_group, adapter_type:) }
    tag2_group { create(:tag_group, adapter_type:) }
  end
end
