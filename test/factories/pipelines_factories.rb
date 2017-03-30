# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2011,2012,2013,2014,2015 Genome Research Ltd.
require 'factory_girl'
require 'control_request_type_creation'

Pipeline.send(:include, ControlRequestTypeCreation)

FactoryGirl.define do
  sequence :plate_creator_name do |n|
    "Plate Creator #{n}"
  end

  factory :asset do
    name                { |_a| generate :asset_name }
    value               ''
    qc_state            ''
    resource            nil
    barcode
    barcode_prefix { |b| b.association(:barcode_prefix) }
  end

  factory :plate_creator_purpose, class: Plate::Creator::PurposeRelationship do |_t|
    plate_creator
    plate_purpose
  end

  factory :plate_creator, class: Plate::Creator do
    name { generate :plate_creator_name }
  end

  factory :control_plate do
    plate_purpose { PlatePurpose.find_by(name: 'Stock plate') }
    name                'Control Plate name'
    value               ''
    descriptors         []
    descriptor_fields   []
    qc_state            ''
    resource            nil
    sti_type            'ControlPlate'
    barcode
  end

  factory :dilution_plate do
    plate_purpose { PlatePurpose.find_by!(name: 'Stock plate') }
    barcode
  end
  factory :gel_dilution_plate do
    plate_purpose { PlatePurpose.find_by!(name: 'Gel Dilution') }
    barcode
  end
  factory :pico_assay_a_plate do
    plate_purpose { PlatePurpose.find_by!(name: 'Pico Assay A') }
    barcode
  end
  factory :pico_assay_b_plate do
    plate_purpose { PlatePurpose.find_by!(name: 'Pico Assay B') }
    barcode
  end
  factory :pico_assay_plate do
    plate_purpose { PlatePurpose.find_by!(name: 'Stock plate') }
    barcode
  end
  factory :pico_dilution_plate do
    plate_purpose { PlatePurpose.find_by!(name: 'Pico Dilution') }
    barcode
  end
  factory :sequenom_qc_plate do
    sequence(:name) { |i| "Sequenom #{i}" }
    plate_purpose { PlatePurpose.find_by!(name: 'Sequenom') }
    barcode
  end
  factory :working_dilution_plate do
    plate_purpose { PlatePurpose.find_by!(name: 'Working Dilution') }
    barcode
  end

  factory :batch do
    item_limit 4
    user
    pipeline
    state                 'pending'
    qc_pipeline_id        ''
    qc_state              'qc_pending'
    assignee_id           { |user| user.association(:user) }
    production_state      nil

    transient do
      request_count 0
    end

    after(:create) do |batch, evaluator|
      if evaluator.request_count.positive?
        batch.batch_requests = create_list(:batch_request, evaluator.request_count, batch: batch)
      end
    end

    factory :multiplexed_batch do
      association(:pipeline, factory: :multiplexed_pipeline)
    end
  end

  factory :pac_bio_sequencing_batch, class: Batch do
    transient do
      target_plate { create(:plate_with_tagged_wells, sample_count: request_count) }
      request_count 0
      assets { create_list(:pac_bio_library_tube, request_count) }
    end

    association(:pipeline, factory: :pac_bio_sequencing_pipeline)

    after(:build) do |batch, evaluator|
      evaluator.assets.each_with_index.map do |asset, index|
        create :pac_bio_sequencing_request,
               asset: asset,
               target_asset: evaluator.target_plate.wells[index],
               request_type: batch.pipeline.request_types.first,
               batch: batch
      end
    end
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
    location

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
    location
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
    name                  { FactoryGirl.generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil
    location              { |location| location.association(:location) }

    association(:workflow, factory: :lab_workflow_for_pipeline)
    after(:build) do |pipeline|
      pipeline.request_types << create(:sequencing_request_type)
      pipeline.add_control_request_type
      pipeline.build_workflow(name: pipeline.name, item_limit: 2, locale: 'Internal', pipeline: pipeline) if pipeline.workflow.nil?
    end
  end

  factory :pac_bio_sequencing_pipeline do
    name { FactoryGirl.generate :pipeline_name }
    active true
    association(:workflow, factory: :lab_workflow_for_pipeline)
    control_request_type_id(-1)

    after(:build) do |pipeline|
      pipeline.request_types << create(:pac_bio_sequencing_request_type)
    end
  end

  factory :qc_pipeline do
    name                  { |_a| FactoryGirl.generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil
    location

    after(:build) do |pipeline|
      pipeline.request_types << create(:request_type)
      pipeline.add_control_request_type
      pipeline.build_workflow(name: pipeline.name, locale: 'Internal', pipeline: pipeline)
    end
  end

  factory :library_creation_pipeline do
    name                  { |_a| FactoryGirl.generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil
    location              { |location| location.association(:location) }

    after(:build) do |pipeline|
      pipeline.request_types << create(:request_type)
      pipeline.add_control_request_type
      pipeline.build_workflow(name: pipeline.name, locale: 'Internal', pipeline: pipeline)
    end
  end

  factory :library_completion, class: IlluminaHtp::Requests::LibraryCompletion do
    request_type { |_target| RequestType.find_by(name: 'Illumina-B Pooled') or raise StandardError, "Could not find 'Illumina-B Pooled' request type" }
    asset        { |target| target.association(:well_with_sample_and_plate) }
    target_asset { |target| target.association(:empty_well) }
    request_purpose
    after(:build) do |request|
      request.request_metadata.fragment_size_required_from = 300
      request.request_metadata.fragment_size_required_to   = 500
    end
  end

  factory :pulldown_library_creation_pipeline do
    name                  { |_a| FactoryGirl.generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil
    location              { |location| location.association(:location) }

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
    workflow      { |workflow| workflow.association(:submission_workflow) }
    pipeline_administrator true
  end

  factory :lab_workflow, class: LabInterface::Workflow do
    name                  { FactoryGirl.generate :lab_workflow_name }
    item_limit            2
    locale                'Internal'
    # Bit grim. Otherwise pipeline behaves a little weird and tries to build a second workflow.
    pipeline { |workflow| workflow.association(:pipeline, workflow: workflow.instance_variable_get('@instance')) }
  end

  factory :lab_workflow_for_pipeline, class: LabInterface::Workflow do
    name                  { |_a| FactoryGirl.generate :lab_workflow_name }
    item_limit            2
    locale                'Internal'
  end

  factory :batch_request do
    batch
    request
    sequence(:position) { |i| i }
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

  factory :location do
    name 'Some fridge'
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

  factory :tag_group do
    name  { generate :tag_group_name }

    transient do
      tag_count 0
    end

    after(:build) do |tag_group, evaluator|
      evaluator.tag_count.times do |i|
        tag_group.tags << create(:tag, map_id: i + 1, tag_group: tag_group)
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
    purpose_id { Purpose.find_by(name: 'PacBio Sheared').id }
  end

  factory :sample_tube_without_barcode, class: Tube do
    name                { |_a| FactoryGirl.generate :asset_name }
    value               ''
    descriptors         []
    descriptor_fields   []
    qc_state            ''
    resource            nil
    barcode             nil
    purpose             { Tube::Purpose.standard_sample_tube }
  end

  factory :empty_sample_tube, class: SampleTube do
    name                { generate :asset_name }
    value               ''
    descriptors         []
    descriptor_fields   []
    qc_state            ''
    resource            nil
    barcode
    purpose { Tube::Purpose.standard_sample_tube }
  end

  factory :sample_tube, parent: :empty_sample_tube do
    transient do
      sample { create(:sample) }
      study { create(:study) }
      project { create(:project) }
    end

    after(:create) do |sample_tube, evaluator|
      create_list(:untagged_aliquot, 1, sample: evaluator.sample, receptacle: sample_tube, study: evaluator.study, project: evaluator.project)
    end
  end

  factory :cherrypick_task do
    name 'New task'
    pipeline_workflow_id { |workflow| workflow.association(:lab_workflow) }
    sorted                nil
    batched               nil
    location              ''
    interactive           nil
  end

  factory :plate_purpose do
    name { generate :purpose_name }
    size 96
    association(:barcode_printer_type, factory: :plate_barcode_printer_type)
    target_type 'Plate'
    asset_shape { AssetShape.default }

    factory :source_plate_purpose do
      after(:build) do |source_plate_purpose, _evaluator|
        source_plate_purpose.source_purpose = source_plate_purpose
      end

      factory :input_plate_purpose, class: PlatePurpose::Input do
        stock_plate true
      end
    end
  end

  factory :purpose do
    name { generate :purpose_name }
    target_type 'Asset'

    factory :stock_purpose do
      stock_plate true
    end
  end

  factory(:tube_purpose, class: Tube::Purpose) do
    name        'Tube purpose'
    target_type 'MultiplexedLibraryTube'
  end

  factory :dilution_plate_purpose do
    name    'Dilution'
  end

  factory :barcode_prefix do
    prefix  'DN'
  end
end
