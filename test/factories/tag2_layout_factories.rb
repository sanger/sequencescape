FactoryGirl.define do
  factory :tag2_layout do
    association(:plate, factory: :plate_with_untagged_wells)
    tag
    user
  end

  factory :tag2_layout_template_submission, class: Tag2Layout::TemplateSubmission do
    submission
    tag2_layout_template
  end
end
