# frozen_string_literal: true

require 'factory_bot'
require 'control_request_type_creation'

Pipeline.include ControlRequestTypeCreation

FactoryBot.define do
  sequence :plate_creator_name do |n|
    "Plate Creator #{n}"
  end

  factory :labware do
    name { generate :asset_name }
  end

  factory :plate_creator_purpose, class: 'Plate::Creator::PurposeRelationship' do |_t|
    plate_creator
    plate_purpose
  end

  factory :plate_creator, class: 'Plate::Creator' do
    name { generate :plate_creator_name }
  end

  factory :control do
    name { 'New control' }
    pipeline
  end

  factory :descriptor do
    name { 'Desc name' }
    value { '' }
    selection { '' }
    task
    kind { '' }
    required { 0 }
    sorter { nil }
    key { '' }
  end

  factory :lab_event do
    descriptors { {} }

    factory :flowcell_event do
      descriptors { { 'Chip Barcode' => 'fcb' } }
    end
  end

  factory :pipeline do
    name { generate :pipeline_name }
    active { true }
    validator_class_name { 'DefaultValidator' }

    transient do
      item_limit { 2 }
      locale { 'Internal' }
    end

    after(:build) do |pipeline, evaluator|
      pipeline.request_types << create(:request_type)
      pipeline.add_control_request_type
      if pipeline.workflow.nil?
        pipeline.build_workflow(
          name: pipeline.name,
          item_limit: evaluator.item_limit,
          locale: evaluator.locale,
          pipeline: pipeline
        )
      end
    end

    factory :multiplexed_pipeline do
      multiplexed { true }
    end
  end

  factory :cherrypick_pipeline do
    transient { request_type { build(:cherrypick_request_type) } }

    name { generate :pipeline_name }
    active { true }
    max_size { 3000 }
    summary { true }
    externally_managed { false }
    min_size { 1 }

    after(:build) do |pipeline, evaluator|
      pipeline.workflow = build :cherrypick_pipeline_workflow, pipeline: pipeline unless pipeline.workflow
      pipeline.request_types << evaluator.request_type
      pipeline.add_control_request_type
    end
  end

  factory :fluidigm_pipeline, class: 'CherrypickPipeline' do
    name { generate :pipeline_name }
    active { true }
    max_size { 192 }
    sorter { 11 }
    summary { false }
    externally_managed { false }
    control_request_type_id { 0 }
    min_size { 1 }

    workflow factory: %i[fluidigm_pipeline_workflow]

    after(:build) { |pipeline| pipeline.request_types << build(:well_request_type) }
  end

  factory :sequencing_pipeline do
    name { generate :pipeline_name }
    active { true }

    workflow { build :lab_workflow_for_pipeline }

    #   association(:workflow, factory: :lab_workflow_for_pipeline)
    after(:build) do |pipeline|
      pipeline.request_types << create(:sequencing_request_type)
      pipeline.add_control_request_type
    end

    trait :with_workflow do
      after(:build) do |pipeline|
        workflow = pipeline.workflow
        create(
          :set_descriptors_task,
          name: 'Specify Dilution Volume',
          workflow: workflow,
          per_item: true,
          descriptor_attributes: [{ kind: 'Text', sorter: 0, name: 'Concentration' }]
        )
        create(:add_spiked_in_control_task, workflow: workflow)
        create(
          :set_descriptors_task,
          workflow: workflow,
          descriptor_attributes: [
            {
              kind: 'Selection',
              sorter: 3,
              name: 'Workflow (Standard or Xp)',
              selection: {
                'Standard' => 'Standard',
                'XP' => 'XP'
              },
              value: 'Standard'
            },
            { kind: 'Text', sorter: 4, name: 'Lane loading concentration (pM)' },
            # We had a bug where the + was being stripped from the beginning of field names
            { kind: 'Text', sorter: 5, name: '+4 field of weirdness' }
          ]
        )
      end
    end
  end

  factory :pac_bio_sequencing_pipeline do
    name { FactoryBot.generate :pipeline_name }
    active { true }

    #  association(:workflow, factory: :lab_workflow_for_pipeline)
    control_request_type_id { -1 }
    workflow { build :lab_workflow_for_pipeline }

    after(:build) { |pipeline| pipeline.request_types << create(:pac_bio_sequencing_request_type) }
  end

  factory :library_completion, class: 'IlluminaHtp::Requests::LibraryCompletion' do
    request_type do
      create(
        :request_type,
        name: 'Illumina-B Pooled',
        key: 'illumina_b_pool',
        request_class_name: 'IlluminaHtp::Requests::LibraryCompletion',
        for_multiplexing: true,
        no_target_asset: false
      )
    end
    asset { |target| target.association(:well_with_sample_and_plate) }
    target_asset { |target| target.association(:empty_well) }
    request_purpose { :standard }
    after(:build) do |request|
      request.request_metadata.fragment_size_required_from = 300
      request.request_metadata.fragment_size_required_to = 500
      request.request_metadata.library_type = create(:library_type)
    end
  end

  factory :pipeline_admin, class: 'User' do
    login { 'ad1' }
    email { |a| "#{a.login}@example.com".downcase }
    pipeline_administrator { true }
  end

  factory :workflow, aliases: [:lab_workflow] do
    name { FactoryBot.generate :lab_workflow_name }
    item_limit { 2 }
    locale { 'Internal' }

    # Bit grim. Otherwise pipeline behaves a little weird and tries to build a second workflow.
    pipeline { |workflow| workflow.association(:pipeline, workflow: workflow.instance_variable_get(:@instance)) }
  end

  factory :lab_workflow_for_pipeline, class: 'Workflow' do
    name { generate :lab_workflow_name }
    item_limit { 2 }
    locale { 'Internal' }

    after(:build) { |workflow| workflow.pipeline = build(:pipeline, workflow: workflow) unless workflow.pipeline }
  end

  factory :fluidigm_pipeline_workflow, class: 'Workflow' do
    name { generate :lab_workflow_name }

    after(:build) do |workflow|
      workflow.pipeline = build(:fluidigm_pipeline, workflow: workflow) unless workflow.pipeline
    end

    tasks { [build(:fluidigm_template_task, workflow: nil), build(:cherrypick_task, workflow: nil)] }
  end

  factory :cherrypick_pipeline_workflow, class: 'Workflow' do
    name { generate :lab_workflow_name }

    after(:build) do |workflow|
      workflow.pipeline = build(:cherrypick_pipeline, workflow: workflow) unless workflow.pipeline
    end

    tasks { [build(:plate_template_task, workflow: nil), build(:cherrypick_task, workflow: nil)] }
  end

  factory :batch_request do
    batch
    request
    sequence(:position) { |i| i }

    factory :cherrypick_batch_request do
      batch
      request factory: %i[cherrypick_request]
    end

    factory :sequencing_batch_request do
      batch
      request factory: %i[complete_sequencing_request]
    end
  end

  factory :request_information_type do
    name { '' }
    key { '' }
    label { '' }
    hide_in_inbox { '' }
  end

  factory :pipeline_request_information_type do
    pipeline { |pipeline| pipeline.association(:pipeline) }
    request_information_type do |request_information_type|
      request_information_type.association(:request_information_type)
    end
  end

  factory :implement do
    name { 'CS03' }
    barcode { 'LE6G' }
    equipment_type { 'Cluster Station' }
  end

  factory :map do
    description { 'A2' }
    asset_size { '96' }
    location_id { 2 }
    row_order { 1 }
    column_order { 8 }
    asset_shape { AssetShape.default }
  end

  factory :plate_template do
    name { 'testtemplate' }
    size { 96 }
  end

  factory :asset_link do
    # Asset links get annoyed if created between nodes which have
    # not been persisted.
    ancestor factory: %i[labware], strategy: :create
    descendant factory: %i[labware], strategy: :create
    direct { true }
  end

  factory :barcode_prefix do
    prefix { 'DN' }
  end
end
