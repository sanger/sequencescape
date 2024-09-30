# frozen_string_literal: true

FactoryBot.define do
  factory :tag2_layout do
    plate factory: %i[plate_with_untagged_wells]
    tag
    user
  end

  factory :tag2_layout_template do |_itlt|
    transient { oligo { generate(:oligo) } }
    sequence(:name) { |n| "Tag 2 layout template #{n}" }
    tag { |tag| tag.association :tag, oligo: }
  end

  factory :tag2_layout_template_submission, class: 'Tag2Layout::TemplateSubmission' do
    submission
    tag2_layout_template
  end
end
