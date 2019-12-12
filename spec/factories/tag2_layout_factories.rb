# frozen_string_literal: true

FactoryBot.define do
  factory :tag2_layout do
    association(:plate, factory: :plate_with_untagged_wells)
    tag
    user
  end

  factory :tag2_layout_template do |_itlt|
    transient do
      oligo { generate :oligo }
    end
    sequence(:name) { |n| "Tag 2 layout template #{n}" }
    tag { |tag| tag.association :tag, oligo: oligo }
  end

  factory :tag2_layout_template_submission, class: 'Tag2Layout::TemplateSubmission' do
    submission
    tag2_layout_template
  end
end
