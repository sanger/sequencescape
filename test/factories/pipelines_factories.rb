#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013,2014,2015 Genome Research Ltd.
require 'factory_girl'
require 'control_request_type_creation'

Pipeline.send(:include, ControlRequestTypeCreation)

FactoryGirl.define do

  sequence :plate_creator_name do |n|
    "Plate Creator #{n}"
  end

  factory :asset do
    name                {|a| FactoryGirl.generate :asset_name }
    value               ""
    qc_state            ""
    resource            nil
    barcode             {|a| FactoryGirl.generate :barcode_number }
    barcode_prefix      {|b| b.association(:barcode_prefix)}
  end

  factory :plate do
    plate_purpose { |_| PlatePurpose.find_by_name('Stock plate') }
    name                "Plate name"
    value               ""
    qc_state            ""
    resource            nil
    sti_type            "Plate"
    barcode             {|a| FactoryGirl.generate :barcode_number }

    factory :source_plate do
      plate_purpose {|pp| pp.association(:source_plate_purpose)}
    end

    factory :child_plate do

      transient do
        parent { create(:source_plate)}
      end

      plate_purpose { |pp| pp.association(:plate_purpose, source_purpose: parent.purpose)}

      after(:create) do |child_plate, evaluator|
        child_plate.parents << evaluator.parent
        child_plate.purpose.source_purpose = evaluator.parent.purpose
      end
    end
  end

  factory :plate_creator_purpose, :class => Plate::Creator::PurposeRelationship do |t|
  end

  factory :plate_creator, :class =>  Plate::Creator do
    name                {|t| FactoryGirl.generate :plate_creator_name }
  end


  factory :control_plate do
    plate_purpose { |_| PlatePurpose.find_by_name('Stock plate') }
    name                "Control Plate name"
    value               ""
    descriptors         []
    descriptor_fields   []
    qc_state            ""
    resource            nil
    sti_type            "ControlPlate"
    barcode             {|a| FactoryGirl.generate :barcode_number }
  end

  factory :dilution_plate do
    plate_purpose { |_| PlatePurpose.find_by_name!('Stock plate') }
    barcode             {|a| FactoryGirl.generate :barcode_number }
  end
  factory :gel_dilution_plate do
    plate_purpose { |_| PlatePurpose.find_by_name!('Gel Dilution') }
    barcode             {|a| FactoryGirl.generate :barcode_number }
  end
  factory :pico_assay_a_plate do
    plate_purpose { |_| PlatePurpose.find_by_name!('Pico Assay A') }
    barcode             {|a| FactoryGirl.generate :barcode_number }
  end
  factory :pico_assay_b_plate do
    plate_purpose { |_| PlatePurpose.find_by_name!('Pico Assay B') }
    barcode             {|a| FactoryGirl.generate :barcode_number }
  end
  factory :pico_assay_plate do
    plate_purpose { |_| PlatePurpose.find_by_name!('Stock plate') }
    barcode             {|a| FactoryGirl.generate :barcode_number }
  end
  factory :pico_dilution_plate do
    plate_purpose { |_| PlatePurpose.find_by_name!('Pico Dilution') }
    barcode             {|a| FactoryGirl.generate :barcode_number }
  end
  factory :sequenom_qc_plate do
    plate_purpose { |_| PlatePurpose.find_by_name!('Sequenom') }
    barcode             {|a| FactoryGirl.generate :barcode_number }
  end
  factory :working_dilution_plate do
    plate_purpose { |_| PlatePurpose.find_by_name!('Working Dilution') }
    barcode             {|a| FactoryGirl.generate :barcode_number }
  end

  factory :batch do |b|
    item_limit            4
    user                  {|user| user.association(:user)}
    pipeline              {|pipeline| pipeline.association(:pipeline)}
    state                 "pending"
    qc_pipeline_id        ""
    qc_state              "qc_pending"
    assignee_id           {|user| user.association(:user)}
    production_state      nil
  end

  factory :control do |c|
    name                  "New control"
    pipeline              {|pipeline| pipeline.association(:pipeline)}
  end

  factory :descriptor do |d|
    name                "Desc name"
    value               ""
    selection           ""
    task                {|task| task.association(:task)}
    kind                ""
    required            0
    sorter              nil
    key                 ""
  end

  factory :lab_event do |e|
  end

  factory :family do |f|
    name                  "New Family name"
    description           "Something goes here"
    relates_to            ""
    task                  { |task|     task.association(:task) }
    workflow              { |workflow| workflow.association(:lab_workflow) }
  end


  factory :lab_workflow_for_pipeline, :class => LabInterface::Workflow do |w|
    name                  {|a| FactoryGirl.generate :lab_workflow_name }
    item_limit            2
    locale                "Internal"
  end

  factory :pipeline, :class => Pipeline do |p|
    name                  {|a| FactoryGirl.generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil
    location              {|location| location.association(:location)}
    after(:build)          do |pipeline|
      pipeline.request_types << create(:request_type )
      pipeline.add_control_request_type
      pipeline.build_workflow(:name => pipeline.name, :item_limit => 2, :locale => 'Internal') if pipeline.workflow.nil?
    end
  end

  factory :sequencing_pipeline, :class => SequencingPipeline do |p|
name                  {|a| FactoryGirl.generate :pipeline_name }
automated             false
active                true
next_pipeline_id      nil
previous_pipeline_id  nil
    location              {|location| location.association(:location)}
    after(:build)          do |pipeline|
      pipeline.request_types << create(:request_type )
      pipeline.add_control_request_type
      pipeline.build_workflow(:name => pipeline.name, :item_limit => 2, :locale => 'Internal') if pipeline.workflow.nil?
    end
  end

  factory :qc_pipeline do |p|
    name                  {|a| FactoryGirl.generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil
    location              {|location| location.association(:location)}

    after(:build) do |pipeline|
      pipeline.request_types << create(:request_type )
      pipeline.add_control_request_type
      pipeline.build_workflow(:name => pipeline.name, :locale => 'Internal')
    end
  end

  factory :library_creation_pipeline do |p|
    name                  {|a| FactoryGirl.generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil
    location              {|location| location.association(:location)}

    after(:build) do |pipeline|
      pipeline.request_types << create(:request_type )
      pipeline.add_control_request_type
      pipeline.build_workflow(:name => pipeline.name, :locale => 'Internal')
    end
  end

  factory :library_completion, :class => IlluminaHtp::Requests::LibraryCompletion do |request|
    request_type { |target| RequestType.find_by_name('Illumina-B Pooled') or raise StandardError, "Could not find 'Illumina-B Pooled' request type" }
    asset        { |target| target.association(:well_with_sample_and_plate) }
    target_asset { |target| target.association(:empty_well) }
    request_purpose
    after(:build) do |request|
      request.request_metadata.fragment_size_required_from = 300
      request.request_metadata.fragment_size_required_to   = 500
    end
  end


  factory :pulldown_library_creation_pipeline do |p|
    name                  {|a| FactoryGirl.generate :pipeline_name }
    automated             false
    active                true
    next_pipeline_id      nil
    previous_pipeline_id  nil
    location              {|location| location.association(:location)}

    after(:build) do |pipeline|
      pipeline.request_types << create(:request_type )
      pipeline.add_control_request_type
      pipeline.build_workflow(:name => pipeline.name, :locale => 'Internal')
    end
  end



  factory :task do |t|
    name                  "New task"
    workflow              {|workflow| workflow.association(:lab_workflow)}
    sorted                nil
    batched               nil
    location              ""
    interactive           nil
  end

  factory :pipeline_admin, :class => User do |u|
    login         "ad1"
    email         {|a| "#{a.login}@example.com".downcase }
    workflow      {|workflow| workflow.association(:submission_workflow)}
    pipeline_administrator true
  end

  factory :lab_workflow, :class => LabInterface::Workflow do |w|
    name                  {|a| FactoryGirl.generate :lab_workflow_name }
    item_limit            2
    locale                "Internal"

    after(:create) do |workflow|
      workflow.pipeline = create(:pipeline, :workflow => workflow)
    end
  end

  factory :batch_request do |br|
    batch
    request
  end

  factory :delayed_message do |dm|
    message            "1"
    queue_attempt_at   "#{Time.now}"
    queue_name         "3"
  end

  factory :request_information_type do |w|
    name                   ""
    key                    ""
    label                  ""
    hide_in_inbox          ""
  end

  factory :pipeline_request_information_type do |prit|
    pipeline                  {|pipeline| pipeline.association(:pipeline)}
    request_information_type  {|request_information_type| request_information_type.association(:request_information_type)}
  end

  factory :location do |l|
    name                   "Some fridge"
  end


  factory :request_information do |ri|
    request_id {|request| activity.association(:request)}
    request_information_type_id {|request_information_type| activity.association(:request_information_type)}
    value nil
  end

  factory :implement do |i|
    name                "CS03"
    barcode             "LE6G"
    equipment_type      "Cluster Station"
  end

  factory :robot do |robot|
    name      "myrobot"
    location  "lab"
  end

  factory :robot_property do |p|
    name      "myrobot"
    value     "lab"
    key       "key_robot"
  end

  factory :pico_set do |ps|
    standard        {|asset| asset.association(:plate)}
    pico_plate1     {|asset| asset.association(:plate)}
    pico_plate2     {|asset| asset.association(:plate)}
    stock           {|asset| asset.association(:plate)}
  end

  factory :map do
    description      "A2"
    asset_size       "96"
    location_id      2
    row_order        1
    column_order     8
  end

  factory :plate_template do |p|
    name      "testtemplate"
    value     96
    size      96
  end

  factory :asset_link do
    ancestor_id     {|asset| asset.association(:asset)}
    descendant_id   {|asset| asset.association(:asset)}
  end

  # Converts i to base 4, then substitutes in ATCG to
  # generate unique tags in sequence
  sequence :oligo do |i|
    i.to_s(4).gsub('0','A').gsub('1','T').gsub('2','C').gsub('3','G')
  end

  factory :tag do |t|
    tag_group
    oligo
  end

  factory :tag_group do |t|
    name "taggroup"

    transient do
      tag_count 0
    end

    after(:create) do |tag_group, evaluator|
      evaluator.tag_count.times do |i|
        tag_group.tags << create(:tag, map_id: i, tag_group: tag_group)
      end
    end
  end

  factory :assign_tags_task do |t|
  end

  factory :assign_tubes_to_multiplexed_wells_task do |t|
  end

  factory :multiplexed_cherrypicking_task do |t|
  end

  factory :attach_infinium_barcode_task do |t|
  end

  factory :tag_groups_task do |t|
  end

  factory :gel_qc_task do |t|
  end

  factory :strip_tube_creation_task do |t|
  end

  factory :plate_transfer_task do |t|
    purpose_id { Purpose.find_by_name('PacBio Sheared').id }
  end

  factory :empty_sample_tube, :class => SampleTube do |sample_tube|
    name                {|a| FactoryGirl.generate :asset_name }
    value               ""
    descriptors         []
    descriptor_fields   []
    qc_state            ""
    resource            nil
    barcode             {|a| FactoryGirl.generate :barcode_number }
    purpose             { Tube::Purpose.standard_sample_tube }
  end
  factory :sample_tube, :parent => :empty_sample_tube do |sample_tube|
    after(:create) do |sample_tube|
      sample_tube.aliquots.create!(:sample => create(:sample))
    end
  end

  factory :cherrypick_task do |t|
    name                  "New task"
    pipeline_workflow_id      {|workflow| workflow.association(:lab_workflow)}
    sorted                nil
    batched               nil
    location              ""
    interactive           nil
  end

  factory :assign_plate_purpose_task do |assign_plate_purpose_task|
    name "Assign a Purpose for Output Plates"
    sorted 3
  end

  factory :plate_purpose do |plate_purpose|
    name    {|a| FactoryGirl.generate :purpose_name }

    factory :source_plate_purpose do |source_plate_purpose|

      after(:build) do |source_plate_purpose, evaluator|
        source_plate_purpose.source_purpose = source_plate_purpose
      end
    end
  end

  factory :purpose do |purpose|
    name {|a| FactoryGirl.generate :purpose_name }
  end

  factory(:tube_purpose, :class => Tube::Purpose) do |purpose|
    name        'Tube purpose'
    target_type 'MultiplexedLibraryTube'
  end

  factory :dilution_plate_purpose do |plate_purpose|
    name    'Dilution'
  end

  factory :barcode_prefix do |b|
    prefix  "DN"
  end

  # A plate that has exactly the right number of wells!
  factory(:plate_for_strip_tubes, :class => Plate) do |plate|
    size 96
    plate_purpose { PlatePurpose.find_by_name('Stock plate') }
    after(:create) do |plate|
      plate.wells.import(
        [ 'A1', 'B1', 'C1', 'D1', 'E1', 'F1', 'G1', 'H1' ].map do |location|
          map = Map.where_description(location).where_plate_size(plate.size).where_plate_shape(AssetShape.find_by_name('Standard')).first or raise StandardError, "No location #{location} on plate #{plate.inspect}"
          create(:tagged_well, :map => map)
        end
      )
    end
  end
end
