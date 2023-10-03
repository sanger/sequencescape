# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    name { 'New task' }
    workflow factory: %i[lab_workflow]
    sorted { nil }
    batched { nil }
    location { '' }
    interactive { nil }
  end

  factory :plate_template_task do
    name { 'Select Plate Template' }
    workflow factory: %i[cherrypick_pipeline_workflow]
    sorted { 1 }
    batched { true }
    lab_activity { true }
  end

  factory :assign_tags_task do
  end

  factory :fluidigm_template_task do
    name { 'Select Plate Template' }
    workflow factory: %i[fluidigm_pipeline_workflow]
    sorted { 1 }
    batched { true }
    lab_activity { true }
  end

  factory :tag_groups_task do
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

  factory :add_spiked_in_control_task do
    name { 'Add Spiked in control' }
    sorted { 1 }
    lab_activity { true }
    workflow
  end

  factory :set_descriptors_task do
    name { 'Set descriptors' }
    sorted { 1 }
    lab_activity { true }
    workflow

    transient { descriptor_attributes { [{ kind: 'Text', sorter: 2, name: 'Comment' }] } }

    descriptors { instance.descriptors.build(descriptor_attributes) }
  end
end
