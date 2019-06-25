# frozen_string_literal: true

FactoryBot.define do
  factory :plate_template_task do
    name { 'Select Plate Template' }
    association(:workflow, factory: :cherrypick_pipeline_workflow)
    sorted { 1 }
    batched { true }
    lab_activity { true }
  end

  factory :assign_tags_task do
  end

  factory :fluidigm_template_task do
    name { 'Select Plate Template' }
    association(:workflow, factory: :fluidigm_pipeline_workflow)
    sorted { 1 }
    batched { true }
    lab_activity { true }
  end

  factory :assign_tubes_to_multiplexed_wells_task do
  end

  factory :multiplexed_cherrypicking_task do
  end

  factory :tag_groups_task do
  end

  factory :strip_tube_creation_task do
  end

  factory :plate_transfer_task do
    purpose_id { create(:plate_purpose).id }
  end

  factory :cherrypick_task do |_t|
    name { 'New task' }
    pipeline_workflow_id { |workflow| workflow.association(:lab_workflow) }
    location { '' }
    sorted { 2 }
  end
end
