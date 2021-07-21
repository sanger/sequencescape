# frozen_string_literal: true

PacBioSamplePrepPipeline.create!(name: 'PacBio Tagged Library Prep') do |pipeline|
  pipeline.sorter = 14
  pipeline.active = true

  pipeline.request_types << RequestType.create!(
    key: 'pacbio_tagged_library_prep',
    name: 'PacBio Tagged Library Prep'
  ) do |request_type|
    request_type.initial_state = 'pending'
    request_type.asset_type = 'Well'
    request_type.order = 1
    request_type.multiples_allowed = false
    request_type.request_class = PacBioSamplePrepRequest
  end

  pipeline.workflow =
    Workflow
      .create!(name: 'PacBio Tagged Library Prep')
      .tap do |workflow|
        [
          {
            class: PrepKitBarcodeTask,
            name: 'DNA Template Prep Kit Box Barcode',
            sorted: 1,
            batched: true,
            lab_activity: true
          },
          {
            class: PlateTransferTask,
            name: 'Transfer to plate',
            sorted: 2,
            batched: nil,
            lab_activity: true,
            purpose: Purpose.find_by(name: 'PacBio Sheared')
          },
          { class: TagGroupsTask, name: 'Tag Groups', sorted: 3, lab_activity: true },
          { class: AssignTagsToTubesTask, name: 'Assign Tags', sorted: 4, lab_activity: true },
          { class: SamplePrepQcTask, name: 'Sample Prep QC', sorted: 5, batched: true, lab_activity: true }
        ].each { |details| details.delete(:class).create!(details.merge(workflow: workflow)) }
      end
end.tap { |pipeline| create_request_information_types(pipeline, 'sequencing_type', 'insert_size') }

PacBioSequencingPipeline.find_by(name: 'PacBio Sequencing').request_types << RequestType.create!(
  key: 'pacbio_multiplexed_sequencing',
  name: 'PacBio Multiplexed Sequencing'
) do |request_type|
  request_type.initial_state = 'pending'
  request_type.asset_type = 'PacBioLibraryTube'
  request_type.morphology = RequestType::CONVERGENT
  request_type.for_multiplexing = true
  request_type.order = 1
  request_type.multiples_allowed = true
  request_type.request_class = PacBioSequencingRequest
  request_type.request_type_validators.build(
    [
      {
        request_option: 'insert_size',
        valid_options: RequestType::Validator::ArrayWithDefault.new([500, 1000, 2000, 5000, 10_000, 20_000], 500),
        request_type: request_type
      },
      {
        request_option: 'sequencing_type',
        valid_options:
          RequestType::Validator::ArrayWithDefault.new(
            ['Standard', 'MagBead', 'MagBead OneCellPerWell v1'],
            'Standard'
          ),
        request_type: request_type
      }
    ]
  )
end

pbs =
  PlatePurpose.create!(
    name: 'PacBio Sequencing',
    target_type: 'Plate',
    default_state: 'pending',
    barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
    cherrypickable_target: false,
    size: 96,
    asset_shape: AssetShape.find_by(name: 'Standard')
  )
AssignTubesToMultiplexedWellsTask.all.each { |task| task.update!(purpose: pbs) }
