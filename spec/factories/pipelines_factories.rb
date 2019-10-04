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

  factory :plate_creator_purpose, class: Plate::Creator::PurposeRelationship do |_t|
    plate_creator
    plate_purpose
  end

  factory :plate_creator, class: Plate::Creator do
    name { generate :plate_creator_name }
  end

  factory :control do
    name { 'New control' }
    pipeline
  end

  factory :descriptor do
    name                { 'Desc name' }
    value               { '' }
    selection           { '' }
    task
    kind                { '' }
    required            { 0 }
    sorter              { nil }
    key                 { '' }
  end

  factory :lab_event do
    factory :flowcell_event do
      descriptors { { 'Chip Barcode' => 'fcb' } }
      descriptor_fields { descriptors.keys }
    end
  end

  factory :pipeline do
    name                  { generate :pipeline_name }
    automated             { false }
    active                { true }
    next_pipeline_id      { nil }
    previous_pipeline_id  { nil }

    transient do
      item_limit { 2 }
      locale { 'Internal' }
    end

    after(:build) do |pipeline, evaluator|
      pipeline.request_types << create(:request_type)
      pipeline.add_control_request_type
      pipeline.build_workflow(name: pipeline.name, item_limit: evaluator.item_limit, locale: evaluator.locale, pipeline: pipeline) if pipeline.workflow.nil?
    end

    factory :multiplexed_pipeline do
      multiplexed { true }
    end
  end

  factory :cherrypick_pipeline do
    name            { generate :pipeline_name }
    automated       { false }
    active          { true }
    max_size        { 3000 }
    summary         { true }
    externally_managed { false }
    min_size { 1 }

    after(:build) do |pipeline|
      pipeline.workflow = build :cherrypick_pipeline_workflow, pipeline: pipeline unless pipeline.workflow
      pipeline.request_types << build(:cherrypick_request_type)
      pipeline.add_control_request_type
    end
  end

  factory :fluidigm_pipeline, class: CherrypickPipeline do
    name                    { generate :pipeline_name }
    active                  { true }
    max_size                { 192 }
    sorter                  { 11 }
    summary                 { false }
    externally_managed      { false }
    control_request_type_id { 0 }
    min_size                { 1 }

    association(:workflow, factory: :fluidigm_pipeline_workflow)

    after(:build) do |pipeline|
      pipeline.request_types << build(:well_request_type)
    end
  end

  factory :sequencing_pipeline do
    name                  { generate :pipeline_name }
    automated             { false }
    active                { true }

    workflow { build :lab_workflow_for_pipeline }

    #   association(:workflow, factory: :lab_workflow_for_pipeline)
    after(:build) do |pipeline|
      pipeline.request_types << create(:sequencing_request_type)
      pipeline.add_control_request_type
      #    pipeline.build_workflow(name: pipeline.name, item_limit: 2, locale: 'Internal', pipeline: pipeline) if pipeline.workflow.nil?
    end
  end

  factory :pac_bio_sequencing_pipeline do
    name { FactoryBot.generate :pipeline_name }
    active { true }
    #  association(:workflow, factory: :lab_workflow_for_pipeline)
    control_request_type_id { -1 }
    workflow { build :lab_workflow_for_pipeline }

    after(:build) do |pipeline|
      pipeline.request_types << create(:pac_bio_sequencing_request_type)
    end
  end

  factory :library_creation_pipeline do
    name                  { |_a| FactoryBot.generate :pipeline_name }
    automated             { false }
    active                { true }
    next_pipeline_id      { nil }
    previous_pipeline_id  { nil }

    after(:build) do |pipeline|
      pipeline.request_types << create(:request_type)
      pipeline.add_control_request_type
      pipeline.build_workflow(name: pipeline.name, locale: 'Internal', pipeline: pipeline)
    end
  end

  factory :multiplexed_library_creation_pipeline do
    name { |_a| FactoryBot.generate :pipeline_name }
    automated             { false }
    active                { true }

    after(:build) do |pipeline|
      pipeline.request_types << create(:request_type)
      pipeline.add_control_request_type
      pipeline.build_workflow(name: pipeline.name, locale: 'Internal', pipeline: pipeline)
    end
  end

  factory :library_completion, class: IlluminaHtp::Requests::LibraryCompletion do
    request_type do
      create(:request_type,
             name: 'Illumina-B Pooled',
             key: 'illumina_b_pool',
             request_class_name: 'IlluminaHtp::Requests::LibraryCompletion',
             for_multiplexing: true,
             no_target_asset: false)
    end
    asset        { |target| target.association(:well_with_sample_and_plate) }
    target_asset { |target| target.association(:empty_well) }
    request_purpose { :standard }
    after(:build) do |request|
      request.request_metadata.fragment_size_required_from = 300
      request.request_metadata.fragment_size_required_to   = 500
      request.request_metadata.library_type                = create(:library_type)
    end
  end

  factory :task do
    name        { 'New task' }
    association(:workflow, factory: :lab_workflow)
    sorted      { nil }
    batched     { nil }
    location    { '' }
    interactive { nil }
  end

  factory :pipeline_admin, class: User do
    login         { 'ad1' }
    email         { |a| "#{a.login}@example.com".downcase }
    pipeline_administrator { true }
  end

  factory :workflow, aliases: [:lab_workflow] do
    name                  { FactoryBot.generate :lab_workflow_name }
    item_limit            { 2 }
    locale                { 'Internal' }
    # Bit grim. Otherwise pipeline behaves a little weird and tries to build a second workflow.
    pipeline { |workflow| workflow.association(:pipeline, workflow: workflow.instance_variable_get('@instance')) }
  end

  factory :lab_workflow_for_pipeline, class: Workflow do
    name                  { generate :lab_workflow_name }
    item_limit            { 2 }
    locale                { 'Internal' }

    after(:build) do |workflow|
      workflow.pipeline = build(:pipeline, workflow: workflow) unless workflow.pipeline
    end
  end

  factory :fluidigm_pipeline_workflow, class: Workflow do
    name { generate :lab_workflow_name }

    after(:build) do |workflow|
      workflow.pipeline = build(:fluidigm_pipeline, workflow: workflow) unless workflow.pipeline
    end

    tasks do
      [
        build(:fluidigm_template_task, workflow: nil),
        build(:cherrypick_task, workflow: nil)
      ]
    end
  end

  factory :cherrypick_pipeline_workflow, class: Workflow do
    name { generate :lab_workflow_name }

    after(:build) do |workflow|
      workflow.pipeline = build(:cherrypick_pipeline, workflow: workflow) unless workflow.pipeline
    end

    tasks do
      [
        build(:plate_template_task, workflow: nil),
        build(:cherrypick_task, workflow: nil)
      ]
    end
  end

  factory :batch_request do
    batch
    request
    sequence(:position) { |i| i }

    factory :cherrypick_batch_request do
      batch
      association(:request, factory: :cherrypick_request)
    end

    factory :sequencing_batch_request do
      batch
      association(:request, factory: :complete_sequencing_request)
    end
  end

  factory :request_information_type do
    name                   { '' }
    key                    { '' }
    label                  { '' }
    hide_in_inbox          { '' }
  end

  factory :pipeline_request_information_type do
    pipeline                  { |pipeline| pipeline.association(:pipeline) }
    request_information_type  { |request_information_type| request_information_type.association(:request_information_type) }
  end

  factory :implement do
    name                { 'CS03' }
    barcode             { 'LE6G' }
    equipment_type      { 'Cluster Station' }
  end

  factory :robot do
    name      { 'myrobot' }
    location  { 'lab' }
  end

  factory :robot_property do
    name      { 'myrobot' }
    value     { 'lab' }
    key       { 'key_robot' }
  end

  factory :map do
    description      { 'A2' }
    asset_size       { '96' }
    location_id      { 2 }
    row_order        { 1 }
    column_order     { 8 }
    asset_shape { AssetShape.default }
  end

  factory :plate_template do
    name      { 'testtemplate' }
    size      { 96 }
  end

  factory :asset_link do
    # Asset links get annoyed if created between nodes which have
    # not been persisted.
    association(:ancestor, factory: :labware, strategy: :create)
    association(:descendant, factory: :labware, strategy: :create)
    direct { true }
  end

  factory :barcode_prefix do
    prefix { 'DN' }
  end
end
