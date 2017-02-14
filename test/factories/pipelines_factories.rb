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

  factory :plate_creator_purpose, class: Plate::Creator::PurposeRelationship do |t|
  end

  factory :plate_creator, class: Plate::Creator do
    name { generate :plate_creator_name }
    plate_purpose
  end

  factory :control_plate do
    plate_purpose { |_| PlatePurpose.find_by(name: 'Stock plate') }
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
    plate_purpose { |_| PlatePurpose.find_by!(name: 'Stock plate') }
    barcode
  end
  factory :gel_dilution_plate do
    plate_purpose { |_| PlatePurpose.find_by!(name: 'Gel Dilution') }
    barcode
  end
  factory :pico_assay_a_plate do
    plate_purpose { |_| PlatePurpose.find_by!(name: 'Pico Assay A') }
    barcode
  end
  factory :pico_assay_b_plate do
    plate_purpose { |_| PlatePurpose.find_by!(name: 'Pico Assay B') }
    barcode
  end
  factory :pico_assay_plate do
    plate_purpose { |_| PlatePurpose.find_by!(name: 'Stock plate') }
    barcode
  end
  factory :pico_dilution_plate do
    plate_purpose { |_| PlatePurpose.find_by!(name: 'Pico Dilution') }
    barcode
  end
  factory :sequenom_qc_plate do
    plate_purpose { |_| PlatePurpose.find_by!(name: 'Sequenom') }
    barcode
  end
  factory :working_dilution_plate do
    plate_purpose { |_| PlatePurpose.find_by!(name: 'Working Dilution') }
    barcode
  end

  factory :batch do |_b|
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
      create_list(:batch_request, evaluator.request_count, batch: batch)
    end
  end

  factory :control do |_c|
    name 'New control'
    pipeline
  end

  factory :descriptor do |_d|
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

  factory :family do |_f|
    name                  'New Family name'
    description           'Something goes here'
    relates_to            ''
    task                  { |task|     task.association(:task) }
    workflow              { |workflow| workflow.association(:lab_workflow) }
  end

  factory :lab_workflow_for_pipeline, class: LabInterface::Workflow do |_w|
    name                  { |_a| FactoryGirl.generate :lab_workflow_name }
    item_limit            2
    locale                'Internal'
  end

  factory :pipeline do
    name                  { generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil
    location              { |location| location.association(:location) }
    after(:build) do |pipeline|
      pipeline.request_types << create(:request_type)
      pipeline.add_control_request_type
      pipeline.build_workflow(name: pipeline.name, item_limit: 2, locale: 'Internal') if pipeline.workflow.nil?
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

    after(:build) do |pipeline|
      pipeline.request_types << build(:well_request_type)
      pipeline.add_control_request_type
      pipeline.build_workflow(name: pipeline.name, item_limit: 3000, locale: 'Internal') if pipeline.workflow.nil?
    end
  end

  factory :sequencing_pipeline do
    name                  { |_a| FactoryGirl.generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil
    location              { |location| location.association(:location) }
    after(:build) do |pipeline|
      pipeline.request_types << create(:request_type)
      pipeline.add_control_request_type
      pipeline.build_workflow(name: pipeline.name, item_limit: 2, locale: 'Internal') if pipeline.workflow.nil?
    end
  end

  factory :qc_pipeline do |_p|
    name                  { |_a| FactoryGirl.generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil
    location

    after(:build) do |pipeline|
      pipeline.request_types << create(:request_type)
      pipeline.add_control_request_type
      pipeline.build_workflow(name: pipeline.name, locale: 'Internal')
    end
  end

  factory :library_creation_pipeline do |_p|
    name                  { |_a| FactoryGirl.generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil
    location              { |location| location.association(:location) }

    after(:build) do |pipeline|
      pipeline.request_types << create(:request_type)
      pipeline.add_control_request_type
      pipeline.build_workflow(name: pipeline.name, locale: 'Internal')
    end
  end

  factory :library_completion, class: IlluminaHtp::Requests::LibraryCompletion do |_request|
    request_type { |_target| RequestType.find_by(name: 'Illumina-B Pooled') or raise StandardError, "Could not find 'Illumina-B Pooled' request type" }
    asset        { |target| target.association(:well_with_sample_and_plate) }
    target_asset { |target| target.association(:empty_well) }
    request_purpose
    after(:build) do |request|
      request.request_metadata.fragment_size_required_from = 300
      request.request_metadata.fragment_size_required_to   = 500
    end
  end

  factory :pulldown_library_creation_pipeline do |_p|
    name                  { |_a| FactoryGirl.generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil
    location              { |location| location.association(:location) }

    after(:build) do |pipeline|
      pipeline.request_types << create(:request_type)
      pipeline.add_control_request_type
      pipeline.build_workflow(name: pipeline.name, locale: 'Internal')
    end
  end

  factory :task do |_t|
    name                  'New task'
    workflow              { |workflow| workflow.association(:lab_workflow) }
    sorted                nil
    batched               nil
    location              ''
    interactive           nil
  end

  factory :pipeline_admin, class: User do |_u|
    login         'ad1'
    email         { |a| "#{a.login}@example.com".downcase }
    workflow      { |workflow| workflow.association(:submission_workflow) }
    pipeline_administrator true
  end

  factory :lab_workflow, class: LabInterface::Workflow do |_w|
    name                  { |_a| FactoryGirl.generate :lab_workflow_name }
    item_limit            2
    locale                'Internal'

    after(:create) do |workflow|
      workflow.pipeline = create(:pipeline, workflow: workflow)
    end
  end

  factory :batch_request do |_br|
    batch
    request
    sequence(:position) { |i| i }
  end

  factory :delayed_message do |_dm|
    message            '1'
    queue_attempt_at   Time.current.to_s
    queue_name         '3'
  end

  factory :request_information_type do |_w|
    name                   ''
    key                    ''
    label                  ''
    hide_in_inbox          ''
  end

  factory :pipeline_request_information_type do |_prit|
    pipeline                  { |pipeline| pipeline.association(:pipeline) }
    request_information_type  { |request_information_type| request_information_type.association(:request_information_type) }
  end

  factory :location do |_l|
    name 'Some fridge'
  end

  factory :request_information do |_ri|
    request_id { |_request| activity.association(:request) }
    request_information_type_id { |_request_information_type| activity.association(:request_information_type) }
    value nil
  end

  factory :implement do |_i|
    name                'CS03'
    barcode             'LE6G'
    equipment_type      'Cluster Station'
  end

  factory :robot do |_robot|
    name      'myrobot'
    location  'lab'
  end

  factory :robot_property do |_p|
    name      'myrobot'
    value     'lab'
    key       'key_robot'
  end

  factory :pico_set do |_ps|
    standard        { |asset| asset.association(:plate) }
    pico_plate1     { |asset| asset.association(:plate) }
    pico_plate2     { |asset| asset.association(:plate) }
    stock           { |asset| asset.association(:plate) }
  end

  factory :map do
    description      'A2'
    asset_size       '96'
    location_id      2
    row_order        1
    column_order     8
  end

  factory :plate_template do |_p|
    name      'testtemplate'
    value     96
    size      96
  end

  factory :asset_link do
    ancestor_id     { |asset| asset.association(:asset) }
    descendant_id   { |asset| asset.association(:asset) }
  end

  # Converts i to base 4, then substitutes in ATCG to
  # generate unique tags in sequence
  sequence :oligo do |i|
    i.to_s(4).tr('0', 'A').tr('1', 'T').tr('2', 'C').tr('3', 'G')
  end

  factory :tag do |_t|
    tag_group
    oligo
  end

  factory :tag_group do |_t|
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

  factory :gel_qc_task do
  end

  factory :strip_tube_creation_task do
  end

  factory :plate_transfer_task do |_t|
    purpose_id { Purpose.find_by(name: 'PacBio Sheared').id }
  end

  factory :sample_tube_without_barcode, class: Tube do |_tube|
    name                { |_a| FactoryGirl.generate :asset_name }
    value               ''
    descriptors         []
    descriptor_fields   []
    qc_state            ''
    resource            nil
    barcode             nil
    purpose             { Tube::Purpose.standard_sample_tube }
  end

  factory :empty_sample_tube, class: SampleTube do |_sample_tube|
    name                { |_a| FactoryGirl.generate :asset_name }
    value               ''
    descriptors         []
    descriptor_fields   []
    qc_state            ''
    resource            nil
    barcode
    purpose { Tube::Purpose.standard_sample_tube }
  end

  factory :sample_tube, parent: :empty_sample_tube do |_sample_tube|
    transient do
      sample { create(:sample) }
      study { create(:study) }
      project { create(:project) }
    end

    after(:create) do |sample_tube, evaluator|
      create_list(:untagged_aliquot, 1, sample: evaluator.sample, receptacle: sample_tube, study: evaluator.study, project: evaluator.project)
    end
  end

  factory :cherrypick_task do |_t|
    name 'New task'
    pipeline_workflow_id { |workflow| workflow.association(:lab_workflow) }
    sorted                nil
    batched               nil
    location              ''
    interactive           nil
  end

  factory :assign_plate_purpose_task do |_assign_plate_purpose_task|
    name 'Assign a Purpose for Output Plates'
    sorted 3
  end

  factory :plate_purpose do |_plate_purpose|
    name { generate :purpose_name }
    size 96
    association(:barcode_printer_type, factory: :plate_barcode_printer_type)
    target_type 'Plate'
    asset_shape { AssetShape.default }

    factory :source_plate_purpose do |_source_plate_purpose|
      after(:build) do |source_plate_purpose, _evaluator|
        source_plate_purpose.source_purpose = source_plate_purpose
      end

      factory :input_plate_purpose, class: PlatePurpose::Input do |_plate_purpose|
        stock_plate true
      end
    end
  end

  factory :purpose do |_purpose|
    name { generate :purpose_name }
    target_type 'Asset'

    factory :stock_purpose do
      stock_plate true
    end
  end

  factory(:tube_purpose, class: Tube::Purpose) do |_purpose|
    name        'Tube purpose'
    target_type 'MultiplexedLibraryTube'
  end

  factory :dilution_plate_purpose do |_plate_purpose|
    name    'Dilution'
  end

  factory :barcode_prefix do |_b|
    prefix  'DN'
  end

  # A plate that has exactly the right number of wells!
  factory(:plate_for_strip_tubes, class: Plate) do |_plate|
    size 96
    plate_purpose { PlatePurpose.find_by(name: 'Stock plate') }
    after(:create) do |plate|
      plate.wells.import(
        %w(A1 B1 C1 D1 E1 F1 G1 H1).map do |location|
          map = Map.where_description(location).where_plate_size(plate.size).where_plate_shape(AssetShape.find_by(name: 'Standard')).first or raise StandardError, "No location #{location} on plate #{plate.inspect}"
          create(:tagged_well, map: map)
        end
      )
    end
  end
end
