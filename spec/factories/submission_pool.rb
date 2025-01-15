# frozen_string_literal: true

FactoryBot.define do
  factory :submission_pool, class: 'SubmissionPool' do
    tag_layout_template_submissions { create_list(:tag_layout_template_submission, 2) }
  end
end
