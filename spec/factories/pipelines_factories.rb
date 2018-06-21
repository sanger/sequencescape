# frozen_string_literal: true

require 'factory_bot'
require 'control_request_type_creation'

Pipeline.send(:include, ControlRequestTypeCreation)

FactoryBot.define do
  sequence :plate_creator_name do |n|
    "Plate Creator #{n}"
  end

  factory :asset do
    name                { |_a| generate :asset_name }
    value               ''
    qc_state            ''
  end

  factory :plate_creator_purpose, class: Plate::Creator::PurposeRelationship do |_t|
    plate_creator
    plate_purpose
  end

  factory :plate_creator, class: Plate::Creator do
    name { generate :plate_creator_name }
  end

  factory :control do
    name 'New control'
    pipeline
  end

  factory :descriptor do
    name                'Desc name'
    value               ''
    selection           ''
    task
    kind                ''
    required            0
    sorter              nil
    key                 ''
  end

  factory :lab_event do |e|
  end

  factory :family do
    name                  'New Family name'
    description           'Something goes here'
    relates_to            ''
    task
    association(:workflow, factory: :lab_workflow)
  end

  factory :pipeline do
    name                  { generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil

    transient do
      item_limit 2
      locale 'Internal'
    end

    after(:build) do |pipeline, evaluator|
      pipeline.request_types << create(:request_type)
      pipeline.add_control_request_type
      pipeline.build_workflow(name: pipeline.name, item_limit: evaluator.item_limit, locale: evaluator.locale, pipeline: pipeline) if pipeline.workflow.nil?
    end

    factory :multiplexed_pipeline do
      multiplexed true
    end
  end

  factory :cherrypick_pipeline do
    name            { generate :pipeline_name }
    automated       false
    active          true
    group_by_parent true
    asset_type      'Well'
    max_size        3000
    summary         true
    externally_managed false
    min_size 1

    association(:workflow, factory: :lab_workflow_for_pipeline, item_limit: 3000)

    after(:build) do |pipeline|
      pipeline.request_types << build(:well_request_type)
      pipeline.add_control_request_type
      pipeline.build_workflow(name: pipeline.name, item_limit: 3000, locale: 'Internal', pipeline: pipeline) if pipeline.workflow.nil?
    end
  end

  factory :sequencing_pipeline do
    name                  { FactoryBot.generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil

    association(:workflow, factory: :lab_workflow_for_pipeline)
    after(:build) do |pipeline|
      pipeline.request_types << create(:sequencing_request_type)
      pipeline.add_control_request_type
      pipeline.build_workflow(name: pipeline.name, item_limit: 2, locale: 'Internal', pipeline: pipeline) if pipeline.workflow.nil?
    end
  end

  factory :pac_bio_sequencing_pipeline do
    name { FactoryBot.generate :pipeline_name }
    active true
    association(:workflow, factory: :lab_workflow_for_pipeline)
    control_request_type_id(-1)

    after(:build) do |pipeline|
      pipeline.request_types << create(:pac_bio_sequencing_request_type)
    end
  end

  factory :qc_pipeline do
    name                  { |_a| FactoryBot.generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil

    after(:build) do |pipeline|
      pipeline.request_types << create(:request_type)
      pipeline.add_control_request_type
      pipeline.build_workflow(name: pipeline.name, locale: 'Internal', pipeline: pipeline)
    end
  end

  factory :library_creation_pipeline do
    name                  { |_a| FactoryBot.generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil

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
    request_purpose :standard
    after(:build) do |request|
      request.request_metadata.fragment_size_required_from = 300
      request.request_metadata.fragment_size_required_to   = 500
      request.request_metadata.library_type                = create(:library_type)
    end
  end

  factory :pulldown_library_creation_pipeline do
    name                  { |_a| FactoryBot.generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil

    after(:build) do |pipeline|
      pipeline.request_types << create(:request_type)
      pipeline.add_control_request_type
      pipeline.build_workflow(name: pipeline.name, locale: 'Internal', pipeline: pipeline)
    end
  end

  factory :task do
    name        'New task'
    association(:workflow, factory: :lab_workflow)
    sorted      nil
    batched     nil
    location    ''
    interactive nil
  end

  factory :pipeline_admin, class: User do
    login         'ad1'
    email         { |a| "#{a.login}@example.com".downcase }
    pipeline_administrator true
  end

  factory :workflow, aliases: [:lab_workflow] do
    name                  { FactoryBot.generate :lab_workflow_name }
    item_limit            2
    locale                'Internal'
    # Bit grim. Otherwise pipeline behaves a little weird and tries to build a second workflow.
    pipeline { |workflow| workflow.association(:pipeline, workflow: workflow.instance_variable_get('@instance')) }
  end

  factory :lab_workflow_for_pipeline, class: Workflow do
    name                  { |_a| FactoryBot.generate :lab_workflow_name }
    item_limit            2
    locale                'Internal'
  end

  factory :batch_request do
    batch
    request
    sequence(:position) { |i| i }

    factory :cherrypick_batch_request do
      batch
      association(:request, factory: :cherrypick_request)
    end
  end

  factory :request_information_type do
    name                   ''
    key                    ''
    label                  ''
    hide_in_inbox          ''
  end

  factory :pipeline_request_information_type do
    pipeline                  { |pipeline| pipeline.association(:pipeline) }
    request_information_type  { |request_information_type| request_information_type.association(:request_information_type) }
  end

  factory :implement do
    name                'CS03'
    barcode             'LE6G'
    equipment_type      'Cluster Station'
  end

  factory :robot do
    name      'myrobot'
    location  'lab'
  end

  factory :robot_property do
    name      'myrobot'
    value     'lab'
    key       'key_robot'
  end

  factory :map do
    description      'A2'
    asset_size       '96'
    location_id      2
    row_order        1
    column_order     8
    asset_shape AssetShape.default
  end

  factory :plate_template do
    name      'testtemplate'
    value     96
    size      96
  end

  factory :asset_link do
    association(:ancestor, factory: :asset)
    association(:descendant, factory: :asset)
  end

  # Converts i to base 4, then substitutes in ATCG to
  # generate unique tags in sequence
  sequence :oligo do |i|
    i.to_s(4).tr('0', 'A').tr('1', 'T').tr('2', 'C').tr('3', 'G')
  end

  factory :tag, aliases: [:tag2] do
    tag_group
    oligo
  end

  factory :tag_group do |_t|
    sequence(:name) { |n| "Tag Group #{n}" }

    transient do
      tag_count 0
    end

    after(:build) do |tag_group, evaluator|
      evaluator.tag_count.times do |i|
        tag_group.tags << create(:tag, map_id: i + 1, tag_group: tag_group)
      end
    end

    factory :tag_group_with_tags do
      transient do
        tag_count 5
      end
    end
  end

  factory(:tag_group_form_object, class: TagGroup::FormObject) do
    skip_create

    sequence(:name) { |n| "Tag Group #{n}" }

    transient do
      oligos_count 0
    end

    after(:build) do |tag_group_form_object, evaluator|
      if evaluator.oligos_count > 0
        o_list = []
        evaluator.oligos_count.times do |i|
          # generates a series of 8-character oligos
          o_list << (16384 + i).to_s(4).tr('0', 'A').tr('1', 'T').tr('2', 'C').tr('3', 'G')
        end
        tag_group_form_object.oligos_text = o_list.join(' ')
      end
    end

    factory :tag_group_form_object_with_oligos do
      transient do
        oligos_count 5
      end
    end
  end

  factory :assign_tags_task do
  end

  factory :assign_tubes_to_multiplexed_wells_task do
  end

  factory :multiplexed_cherrypicking_task do
  end

  factory :attach_infinium_barcode_task do
  end

  factory :tag_groups_task do
  end

  factory :strip_tube_creation_task do
  end

  factory :plate_transfer_task do
    purpose_id { create(:plate_purpose).id }
  end

  factory :cherrypick_task do |_t|
    name 'New task'
    pipeline_workflow_id { |workflow| workflow.association(:lab_workflow) }
    sorted                nil
    location              ''
    batched               nil
    interactive           nil
  end

  factory :barcode_prefix do
    prefix 'DN'
  end
end
