# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015,2016 Genome Research Ltd.

next_gen_sequencing = Submission::Workflow.find_by!(key: 'short_read_sequencing')
PacBioSamplePrepPipeline.create!(name: 'PacBio Tagged Library Prep') do |pipeline|
  pipeline.sorter               = 14
  pipeline.automated            = false
  pipeline.active               = true
  pipeline.asset_type           = 'PacBioLibraryTube'
  pipeline.group_by_parent      = true

  pipeline.location = Location.find_by(name: 'PacBio library prep freezer') or raise StandardError, "Cannot find 'PacBio library prep freezer' location"

  pipeline.request_types << RequestType.create!(workflow: next_gen_sequencing, key: 'pacbio_tagged_library_prep', name: 'PacBio Tagged Library Prep') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'Well'
    request_type.order             = 1
    request_type.multiples_allowed = false
    request_type.request_class = PacBioSamplePrepRequest
  end

  pipeline.workflow = LabInterface::Workflow.create!(name: 'PacBio Tagged Library Prep').tap do |workflow|
    [
      { class: PrepKitBarcodeTask,    name: 'DNA Template Prep Kit Box Barcode',    sorted: 1, batched: true, lab_activity: true },
      { class: PlateTransferTask,     name: 'Transfer to plate',                    sorted: 2, batched: nil,  lab_activity: true, purpose: Purpose.find_by(name: 'PacBio Sheared') },
      { class: TagGroupsTask,         name: 'Tag Groups',                           sorted: 3, lab_activity: true },
      { class: AssignTagsToTubesTask, name: 'Assign Tags',                          sorted: 4, lab_activity: true },
      { class: SamplePrepQcTask,      name: 'Sample Prep QC',                       sorted: 5, batched: true, lab_activity: true }
     ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'sequencing_type', 'insert_size')
end

PacBioSequencingPipeline.find_by(name: 'PacBio Sequencing').request_types << RequestType.create!(workflow: next_gen_sequencing, key: 'pacbio_multiplexed_sequencing', name: 'PacBio Multiplexed Sequencing') do |request_type|
  request_type.initial_state     = 'pending'
  request_type.asset_type        = 'PacBioLibraryTube'
  request_type.morphology        = RequestType::CONVERGENT
  request_type.for_multiplexing  = true
  request_type.order             = 1
  request_type.multiples_allowed = true
  request_type.request_class     = PacBioSequencingRequest
  request_type.request_type_validators.build([
    { request_option: 'insert_size',
      valid_options: RequestType::Validator::ArrayWithDefault.new([500, 1000, 2000, 5000, 10000, 20000], 500),
      request_type: request_type },
    { request_option: 'sequencing_type',
      valid_options: RequestType::Validator::ArrayWithDefault.new(['Standard', 'MagBead', 'MagBead OneCellPerWell v1'], 'Standard'),
      request_type: request_type }
  ])
end

pbs = PlatePurpose.create!(
  name: 'PacBio Sequencing',
  target_type: 'Plate',
  default_state: 'pending',
  barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
  cherrypickable_target: false,
  cherrypickable_source: false,
  size: 96,
  asset_shape: AssetShape.find_by(name: 'Standard'),
  barcode_for_tecan: 'ean13_barcode'
)
AssignTubesToMultiplexedWellsTask.all.each { |task| task.update_attributes!(purpose: pbs) }

set_pipeline_flow_to('PacBio Tagged Library Prep' => 'PacBio Sequencing')
