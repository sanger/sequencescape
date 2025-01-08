# frozen_string_literal: true

FactoryBot.define do
  factory :work_completion do
    target { create(:labware) }
    user { create(:user) }
    submissions { create_list(:submission, 3) }
  end
end
