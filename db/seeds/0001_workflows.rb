# frozen_string_literal: true

require 'control_request_type_creation'

Pipeline.include ControlRequestTypeCreation
Pipeline.send(:before_save, :add_control_request_type)

RequestType.include RequestTypePurposeCreation
RequestType.send(:before_validation, :add_request_purpose)

ProductLine.create(name: 'Illumina-A')
ProductLine.create(name: 'Illumina-B')
ProductLine.create(name: 'Illumina-C')
ProductLine.create(name: 'Illumina-HTP')

#### RequestInformationTypes
request_information_types_data = [
  ['Fragment size required (from)', 'fragment_size_required_from', 'Fragment size required (from)', 0],
  ['Fragment size required (to)', 'fragment_size_required_to', 'Fragment size required (to)', 0],
  ['Read length', 'read_length', 'Read length', 0],
  ['Library type', 'library_type', 'Library type', 0],
  ['Concentration', 'concentration', 'Concentration', 1],
  ['Concentration', 'concentration', 'Vol.', 0],
  ['Sequencing Type', 'sequencing_type', 'Sequencing Type', 0],
  ['Insert Size', 'insert_size', 'Insert Size', 0]
]
request_information_types_data.each do |data|
  RequestInformationType.create!(name: data[0], key: data[1], label: data[2], hide_in_inbox: data[3])
end

REQUEST_INFORMATION_TYPES = RequestInformationType.all.index_by { |t| t.key }.freeze
def create_request_information_types(pipeline, *keys)
  PipelineRequestInformationType.create!(
    keys.map { |k| { pipeline: pipeline, request_information_type: REQUEST_INFORMATION_TYPES[k] } }
  )
end

##################################################################################################################
# Next-gen sequencing
##################################################################################################################

RequestType.create!(
  key: 'library_creation',
  name: 'Library creation',
  deprecated: true,
  billable: true,
  initial_state: 'pending',
  asset_type: 'SampleTube',
  order: 1,
  multiples_allowed: false,
  request_class: LibraryCreationRequest
)

RequestType.create!(
  key: 'illumina_c_library_creation',
  name: 'Illumina-C Library creation',
  product_line: ProductLine.find_by(name: 'Illumina-C'),
  billable: true,
  initial_state: 'pending',
  asset_type: 'SampleTube',
  order: 1,
  multiples_allowed: false,
  request_class: LibraryCreationRequest
)

RequestType.create!(
  key: 'multiplexed_library_creation',
  name: 'Multiplexed library creation',
  billable: true,
  initial_state: 'pending',
  asset_type: 'SampleTube',
  order: 1,
  multiples_allowed: false,
  request_class: MultiplexedLibraryCreationRequest,
  for_multiplexing: true
)

RequestType.create!(
  key: 'illumina_b_multiplexed_library_creation',
  name: 'Illumina-B Multiplexed Library Creation',
  product_line: ProductLine.find_by(name: 'Illumina-B'),
  deprecated: true,
  billable: true,
  initial_state: 'pending',
  asset_type: 'SampleTube',
  order: 1,
  multiples_allowed: false,
  request_class: MultiplexedLibraryCreationRequest,
  for_multiplexing: true
)

RequestType.create!(
  key: 'illumina_c_multiplexed_library_creation',
  name: 'Illumina-C Multiplexed Library Creation',
  product_line: ProductLine.find_by(name: 'Illumina-C'),
  billable: true,
  initial_state: 'pending',
  asset_type: 'SampleTube',
  order: 1,
  multiples_allowed: false,
  request_class: MultiplexedLibraryCreationRequest,
  for_multiplexing: true
)

cluster_formation_se_request_type =
  %w[a b c].map do |pl|
    RequestType.create!(
      key: "illumina_#{pl}_single_ended_sequencing",
      name: "Illumina-#{pl.upcase} Single ended sequencing",
      product_line: ProductLine.find_by(name: "Illumina-#{pl.upcase}")
    ) do |request_type|
      request_type.billable = true
      request_type.initial_state = 'pending'
      request_type.asset_type = 'LibraryTube'
      request_type.order = 2
      request_type.multiples_allowed = true
      request_type.request_class = SequencingRequest
    end
  end << RequestType.create!(
    key: 'single_ended_sequencing',
    name: 'Single ended sequencing',
    deprecated: true
  ) do |request_type|
    request_type.billable = true
    request_type.initial_state = 'pending'
    request_type.asset_type = 'LibraryTube'
    request_type.order = 2
    request_type.multiples_allowed = true
    request_type.request_class = SequencingRequest
  end

SequencingPipeline
  .create!(
    name: 'Cluster formation SE (spiked in controls)',
    request_types: cluster_formation_se_request_type
  ) do |pipeline|
    pipeline.sorter = 2
    pipeline.active = true

    pipeline.workflow =
      Workflow
        .create!(name: 'Cluster formation SE (spiked in controls)') do |workflow|
          workflow.locale = 'Internal'
          workflow.item_limit = 8
        end
        .tap do |workflow|
          [
            # NOTE: Yes, there's a typo in the name here:
            { class: SetDescriptorsTask, name: 'Specify Dilution Volume ', sorted: 1, batched: true },
            { class: AddSpikedInControlTask, name: 'Add Spiked in Control', sorted: 2, batched: true },
            {
              class: SetDescriptorsTask,
              name: 'Cluster generation',
              sorted: 4,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Quality control',
              sorted: 5,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Lin/block/hyb/load',
              sorted: 6,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            }
          ].each { |details| details.delete(:class).create!(details.merge(workflow:)) }
        end
  end
  .tap do |pipeline|
    PipelineRequestInformationType.create!(
      pipeline: pipeline,
      request_information_type: RequestInformationType.find_by(key: 'read_length')
    )
    PipelineRequestInformationType.create!(
      pipeline: pipeline,
      request_information_type: RequestInformationType.find_by(key: 'library_type')
    )
    PipelineRequestInformationType.create!(
      pipeline: pipeline,
      request_information_type: RequestInformationType.find_by(label: 'Vol.')
    )
  end

SequencingPipeline
  .create!(name: 'Cluster formation SE', request_types: cluster_formation_se_request_type) do |pipeline|
    pipeline.sorter = 2
    pipeline.active = true

    pipeline.workflow =
      Workflow
        .create!(name: 'Cluster formation SE') do |workflow|
          workflow.locale = 'Internal'
          workflow.item_limit = 8
        end
        .tap do |workflow|
          [
            # NOTE: Yes, there's a typo in the name here:
            { class: SetDescriptorsTask, name: 'Specify Dilution Volume ', sorted: 1, batched: true },
            {
              class: SetDescriptorsTask,
              name: 'Cluster generation',
              sorted: 3,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Quality control',
              sorted: 4,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Lin/block/hyb/load',
              sorted: 5,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            }
          ].each { |details| details.delete(:class).create!(details.merge(workflow:)) }
        end
  end
  .tap do |pipeline|
    create_request_information_types(pipeline, 'read_length', 'library_type')
    PipelineRequestInformationType.create!(
      pipeline: pipeline,
      request_information_type: RequestInformationType.find_by(label: 'Vol.')
    )
  end

SequencingPipeline
  .create!(name: 'Cluster formation SE (no controls)', request_types: cluster_formation_se_request_type) do |pipeline|
    pipeline.sorter = 2
    pipeline.active = true

    pipeline.workflow =
      Workflow
        .create!(name: 'Cluster formation SE (no controls)') do |workflow|
          workflow.locale = 'Internal'
          workflow.item_limit = 8
        end
        .tap do |workflow|
          [
            # NOTE: Yes, there's a typo in the name here:
            { class: SetDescriptorsTask, name: 'Specify Dilution Volume ', sorted: 1, batched: true },
            {
              class: SetDescriptorsTask,
              name: 'Cluster generation',
              sorted: 3,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Quality control',
              sorted: 4,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Lin/block/hyb/load',
              sorted: 5,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            }
          ].each { |details| details.delete(:class).create!(details.merge(workflow:)) }
        end
  end
  .tap do |pipeline|
    create_request_information_types(pipeline, 'read_length', 'library_type')
    PipelineRequestInformationType.create!(
      pipeline: pipeline,
      request_information_type: RequestInformationType.find_by(label: 'Vol.')
    )
  end

single_ended_hi_seq_sequencing =
  %w[a b c].map do |pl|
    RequestType.create!(
      key: "illumina_#{pl}_single_ended_hi_seq_sequencing",
      name: "Illumina-#{pl.upcase} Single ended hi seq sequencing",
      product_line: ProductLine.find_by(name: "Illumina-#{pl.upcase}")
    ) do |request_type|
      request_type.billable = true
      request_type.initial_state = 'pending'
      request_type.asset_type = 'LibraryTube'
      request_type.order = 2
      request_type.multiples_allowed = true
      request_type.request_class = HiSeqSequencingRequest
    end
  end << RequestType.create!(
    key: 'single_ended_hi_seq_sequencing',
    name: 'Single ended hi seq sequencing',
    deprecated: true
  ) do |request_type|
    request_type.billable = true
    request_type.initial_state = 'pending'
    request_type.asset_type = 'LibraryTube'
    request_type.order = 2
    request_type.multiples_allowed = true
    request_type.request_class = HiSeqSequencingRequest
  end

SequencingPipeline
  .create!(name: 'Cluster formation SE HiSeq', request_types: single_ended_hi_seq_sequencing) do |pipeline|
    pipeline.sorter = 2
    pipeline.active = true

    pipeline.workflow =
      Workflow
        .create!(name: 'Cluster formation SE HiSeq') do |workflow|
          workflow.locale = 'Internal'
          workflow.item_limit = 8
        end
        .tap do |workflow|
          [
            # NOTE: Yes, there's a typo in the name here:
            { class: SetDescriptorsTask, name: 'Specify Dilution Volume ', sorted: 1, batched: true },
            {
              class: SetDescriptorsTask,
              name: 'Cluster generation',
              sorted: 3,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Quality control',
              sorted: 4,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Lin/block/hyb/load',
              sorted: 5,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            }
          ].each { |details| details.delete(:class).create!(details.merge(workflow:)) }
        end
  end
  .tap do |pipeline|
    create_request_information_types(pipeline, 'read_length', 'library_type')
    PipelineRequestInformationType.create!(
      pipeline: pipeline,
      request_information_type: RequestInformationType.find_by(label: 'Vol.')
    )
  end

SequencingPipeline
  .create!(
    name: 'Cluster formation SE HiSeq (no controls)',
    request_types: single_ended_hi_seq_sequencing
  ) do |pipeline|
    pipeline.sorter = 2
    pipeline.active = true

    pipeline.workflow =
      Workflow
        .create!(name: 'Cluster formation SE HiSeq (no controls)') do |workflow|
          workflow.locale = 'Internal'
          workflow.item_limit = 8
        end
        .tap do |workflow|
          [
            # NOTE: Yes, there's a typo in the name here:
            { class: SetDescriptorsTask, name: 'Specify Dilution Volume ', sorted: 1, batched: true },
            {
              class: SetDescriptorsTask,
              name: 'Cluster generation',
              sorted: 3,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Quality control',
              sorted: 4,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Lin/block/hyb/load',
              sorted: 5,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            }
          ].each { |details| details.delete(:class).create!(details.merge(workflow:)) }
        end
  end
  .tap do |pipeline|
    create_request_information_types(pipeline, 'read_length', 'library_type')
    PipelineRequestInformationType.create!(
      pipeline: pipeline,
      request_information_type: RequestInformationType.find_by(label: 'Vol.')
    )
  end

cluster_formation_pe_request_types =
  %w[a b c].map do |pl|
    RequestType.create!(
      key: "illumina_#{pl}_paired_end_sequencing",
      name: "Illumina-#{pl.upcase} Paired end sequencing",
      product_line: ProductLine.find_by(name: "Illumina-#{pl.upcase}")
    ) do |request_type|
      request_type.billable = true
      request_type.initial_state = 'pending'
      request_type.asset_type = 'LibraryTube'
      request_type.order = 2
      request_type.multiples_allowed = true
      request_type.request_class = SequencingRequest
    end
  end << RequestType.create!(
    key: 'paired_end_sequencing',
    name: 'Paired end sequencing',
    deprecated: true
  ) do |request_type|
    request_type.billable = true
    request_type.initial_state = 'pending'
    request_type.asset_type = 'LibraryTube'
    request_type.order = 2
    request_type.multiples_allowed = true
    request_type.request_class = SequencingRequest
  end

hiseq_2500_request_types =
  %w[a b c].map do |pl|
    RequestType.create!(
      key: "illumina_#{pl}_hiseq_2500_paired_end_sequencing",
      name: "Illumina-#{pl.upcase} HiSeq 2500 Paired end sequencing",
      asset_type: 'LibraryTube',
      order: 2,
      initial_state: 'pending',
      multiples_allowed: true,
      request_class_name: 'HiSeqSequencingRequest',
      product_line: ProductLine.find_by(name: "Illumina-#{pl.upcase}")
    )
  end

hiseq_2500_se_request_types =
  %w[a b c].map do |pl|
    RequestType.create!(
      key: "illumina_#{pl}_hiseq_2500_single_end_sequencing",
      name: "Illumina-#{pl.upcase} HiSeq 2500 Single end sequencing",
      asset_type: 'LibraryTube',
      order: 2,
      initial_state: 'pending',
      multiples_allowed: true,
      request_class_name: 'HiSeqSequencingRequest',
      product_line: ProductLine.find_by(name: "Illumina-#{pl.upcase}")
    )
  end

SequencingPipeline
  .create!(name: 'Cluster formation PE', request_types: cluster_formation_pe_request_types) do |pipeline|
    pipeline.sorter = 3
    pipeline.active = true

    pipeline.workflow =
      Workflow
        .create!(name: 'Cluster formation PE') do |workflow|
          workflow.locale = 'Internal'
          workflow.item_limit = 8
        end
        .tap do |workflow|
          [
            { class: SetDescriptorsTask, name: 'Specify Dilution Volume', sorted: 1, batched: true },
            {
              class: SetDescriptorsTask,
              name: 'Cluster generation',
              sorted: 3,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Quality control',
              sorted: 4,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Read 1 Lin/block/hyb/load',
              sorted: 5,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Read 2 Cluster/Lin/block/hyb/load',
              sorted: 6,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            }
          ].each { |details| details.delete(:class).create!(details.merge(workflow:)) }
        end
  end
  .tap do |pipeline|
    create_request_information_types(pipeline, 'read_length', 'library_type')
    PipelineRequestInformationType.create!(
      pipeline: pipeline,
      request_information_type: RequestInformationType.find_by(label: 'Vol.')
    )
  end

SequencingPipeline
  .create!(name: 'Cluster formation PE (no controls)', request_types: cluster_formation_pe_request_types) do |pipeline|
    pipeline.sorter = 8
    pipeline.active = true

    pipeline.workflow =
      Workflow
        .create!(name: 'Cluster formation PE (no controls)') do |workflow|
          workflow.locale = 'Internal'
          workflow.item_limit = 8
        end
        .tap do |workflow|
          [
            { class: SetDescriptorsTask, name: 'Specify Dilution Volume', sorted: 1, batched: true },
            { class: SetDescriptorsTask, name: 'Cluster generation', sorted: 3, batched: true, lab_activity: true },
            { class: SetDescriptorsTask, name: 'Quality control', sorted: 4, batched: true, lab_activity: true },
            {
              class: SetDescriptorsTask,
              name: 'Read 1 Lin/block/hyb/load',
              sorted: 5,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Read 2 Cluster/Lin/block/hyb/load',
              sorted: 6,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            }
          ].each { |details| details.delete(:class).create!(details.merge(workflow:)) }
        end
  end
  .tap { |pipeline| create_request_information_types(pipeline, 'read_length', 'library_type') }

SequencingPipeline
  .create!(
    name: 'Cluster formation PE (spiked in controls)',
    request_types: cluster_formation_pe_request_types
  ) do |pipeline|
    pipeline.sorter = 8
    pipeline.active = true

    pipeline.workflow =
      Workflow
        .create!(name: 'Cluster formation PE (spiked in controls)') do |workflow|
          workflow.locale = 'Internal'
          workflow.item_limit = 8
        end
        .tap do |workflow|
          [
            { class: SetDescriptorsTask, name: 'Specify Dilution Volume', sorted: 1, batched: true },
            { class: SetDescriptorsTask, name: 'Cluster generation', sorted: 3, batched: true, lab_activity: true },
            {
              class: AddSpikedInControlTask,
              name: 'Add Spiked in Control',
              sorted: 4,
              batched: true,
              lab_activity: true
            },
            { class: SetDescriptorsTask, name: 'Quality control', sorted: 5, batched: true, lab_activity: true },
            {
              class: SetDescriptorsTask,
              name: 'Read 1 Lin/block/hyb/load',
              sorted: 6,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Read 2 Cluster/Lin/block/hyb/load',
              sorted: 7,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            }
          ].each { |details| details.delete(:class).create!(details.merge(workflow:)) }
        end
  end
  .tap do |pipeline|
    create_request_information_types(pipeline, 'read_length', 'library_type')
    PipelineRequestInformationType.create!(
      pipeline: pipeline,
      request_information_type: RequestInformationType.find_by(label: 'Vol.')
    )
  end

SequencingPipeline
  .create!(
    name: 'HiSeq Cluster formation PE (spiked in controls)',
    request_types: cluster_formation_pe_request_types
  ) do |pipeline|
    pipeline.sorter = 9
    pipeline.active = true

    pipeline.workflow =
      Workflow
        .create!(name: 'HiSeq Cluster formation PE (spiked in controls)') do |workflow|
          workflow.locale = 'Internal'
          workflow.item_limit = 8
        end
        .tap do |workflow|
          [
            { class: SetDescriptorsTask, name: 'Specify Dilution Volume', sorted: 1, batched: true },
            { class: SetDescriptorsTask, name: 'Cluster generation', sorted: 3, batched: true, lab_activity: true },
            {
              class: AddSpikedInControlTask,
              name: 'Add Spiked in Control',
              sorted: 4,
              batched: true,
              lab_activity: true
            },
            { class: SetDescriptorsTask, name: 'Quality control', sorted: 5, batched: true, lab_activity: true },
            {
              class: SetDescriptorsTask,
              name: 'Read 1 Lin/block/hyb/load',
              sorted: 6,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Read 2 Cluster/Lin/block/hyb/load',
              sorted: 7,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            }
          ].each { |details| details.delete(:class).create!(details.merge(workflow:)) }
        end
  end
  .tap do |pipeline|
    create_request_information_types(pipeline, 'read_length', 'library_type')
    PipelineRequestInformationType.create!(
      pipeline: pipeline,
      request_information_type: RequestInformationType.find_by(label: 'Vol.')
    )
  end

SequencingPipeline
  .create!(name: 'HiSeq 2500 PE (spiked in controls)', request_types: hiseq_2500_request_types) do |pipeline|
    pipeline.sorter = 9
    pipeline.max_size = 2
    pipeline.active = true

    pipeline.workflow =
      Workflow
        .create!(name: 'HiSeq 2500 PE (spiked in controls)') do |workflow|
          workflow.locale = 'Internal'
          workflow.item_limit = 2
        end
        .tap do |workflow|
          [
            { class: SetDescriptorsTask, name: 'Specify Dilution Volume', sorted: 1, batched: true },
            {
              class: AddSpikedInControlTask,
              name: 'Add Spiked in Control',
              sorted: 3,
              batched: true,
              lab_activity: true
            },
            { class: SetDescriptorsTask, name: 'Quality control', sorted: 4, batched: true, lab_activity: true },
            {
              class: SetDescriptorsTask,
              name: 'Read 1 Lin/block/hyb/load',
              sorted: 5,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Read 2 Cluster/Lin/block/hyb/load',
              sorted: 6,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            }
          ].each { |details| details.delete(:class).create!(details.merge(workflow:)) }
        end
  end
  .tap do |pipeline|
    create_request_information_types(pipeline, 'read_length', 'library_type')
    PipelineRequestInformationType.create!(
      pipeline: pipeline,
      request_information_type: RequestInformationType.find_by(label: 'Vol.')
    )
  end

SequencingPipeline
  .create!(name: 'HiSeq 2500 SE (spiked in controls)', request_types: hiseq_2500_se_request_types) do |pipeline|
    pipeline.sorter = 9
    pipeline.max_size = 2
    pipeline.active = true

    pipeline.workflow =
      Workflow
        .create!(name: 'HiSeq 2500 SE (spiked in controls)') do |workflow|
          workflow.locale = 'Internal'
          workflow.item_limit = 2
        end
        .tap do |workflow|
          [
            { class: SetDescriptorsTask, name: 'Specify Dilution Volume', sorted: 1, batched: true },
            {
              class: AddSpikedInControlTask,
              name: 'Add Spiked in Control',
              sorted: 3,
              batched: true,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Quality control',
              sorted: 4,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Lin/block/hyb/load',
              sorted: 5,
              batched: true,
              interactive: false,
              per_item: false,
              lab_activity: true
            }
          ].each { |details| details.delete(:class).create!(details.merge(workflow:)) }
        end
  end
  .tap do |pipeline|
    create_request_information_types(pipeline, 'read_length', 'library_type')
    PipelineRequestInformationType.create!(
      pipeline: pipeline,
      request_information_type: RequestInformationType.find_by(label: 'Vol.')
    )
  end

SequencingPipeline
  .create!(
    name: 'Cluster formation SE HiSeq (spiked in controls)',
    request_types: cluster_formation_pe_request_types
  ) do |pipeline|
    pipeline.sorter = 8
    pipeline.active = true

    pipeline.workflow =
      Workflow
        .create!(name: 'Cluster formation SE HiSeq (spiked in controls)') do |workflow|
          workflow.locale = 'Internal'
          workflow.item_limit = 8
        end
        .tap do |workflow|
          [
            { class: SetDescriptorsTask, name: 'Specify Dilution Volume', sorted: 1, batched: true },
            { class: SetDescriptorsTask, name: 'Cluster generation', sorted: 3, batched: true, lab_activity: true },
            {
              class: AddSpikedInControlTask,
              name: 'Add Spiked in Control',
              sorted: 4,
              batched: true,
              lab_activity: true
            },
            { class: SetDescriptorsTask, name: 'Quality control', sorted: 5, batched: true, lab_activity: true },
            {
              class: SetDescriptorsTask,
              name: 'Read 1 Lin/block/hyb/load',
              sorted: 6,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            }
          ].each { |details| details.delete(:class).create!(details.merge(workflow:)) }
        end
  end
  .tap do |pipeline|
    create_request_information_types(pipeline, 'read_length', 'library_type')
    PipelineRequestInformationType.create!(
      pipeline: pipeline,
      request_information_type: RequestInformationType.find_by(label: 'Vol.')
    )
  end

# TODO: This pipeline has been cloned from the 'Cluster formation PE (no controls)'.  Needs checking
SequencingPipeline
  .create!(name: 'HiSeq Cluster formation PE (no controls)') do |pipeline|
    pipeline.sorter = 8
    pipeline.active = true

    %w[a b c].each do |pl|
      pipeline.request_types << RequestType.create!(
        key: "illumina_#{pl}_hiseq_paired_end_sequencing",
        name: "Illumina-#{pl.upcase} HiSeq Paired end sequencing",
        product_line: ProductLine.find_by(name: "Illumina-#{pl.upcase}")
      ) do |request_type|
        request_type.billable = true
        request_type.initial_state = 'pending'
        request_type.asset_type = 'LibraryTube'
        request_type.order = 2
        request_type.multiples_allowed = true
        request_type.request_class = HiSeqSequencingRequest
      end
    end
    pipeline.request_types << RequestType.create!(
      key: 'hiseq_paired_end_sequencing',
      name: 'HiSeq Paired end sequencing',
      deprecated: true
    ) do |request_type|
      request_type.billable = true
      request_type.initial_state = 'pending'
      request_type.asset_type = 'LibraryTube'
      request_type.order = 2
      request_type.multiples_allowed = true
      request_type.request_class = HiSeqSequencingRequest
    end

    pipeline.workflow =
      Workflow
        .create!(name: 'HiSeq Cluster formation PE (no controls)') do |workflow|
          workflow.locale = 'Internal'
          workflow.item_limit = 8
        end
        .tap do |workflow|
          [
            { class: SetDescriptorsTask, name: 'Specify Dilution Volume', sorted: 1, batched: true },
            { class: SetDescriptorsTask, name: 'Cluster generation', sorted: 3, batched: true, lab_activity: true },
            { class: SetDescriptorsTask, name: 'Quality control', sorted: 4, batched: true, lab_activity: true },
            {
              class: SetDescriptorsTask,
              name: 'Read 1 Lin/block/hyb/load',
              sorted: 5,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Read 2 Cluster/Lin/block/hyb/load',
              sorted: 6,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            }
          ].each { |details| details.delete(:class).create!(details.merge(workflow:)) }
        end
  end
  .tap do |pipeline|
    create_request_information_types(pipeline, 'read_length', 'library_type')
    PipelineRequestInformationType.create!(
      pipeline: pipeline,
      request_information_type: RequestInformationType.find_by(label: 'Vol.')
    )
  end

##################################################################################################################
# Microarray genotyping
##################################################################################################################

CherrypickPipeline.create!(name: 'Cherrypick') do |pipeline|
  pipeline.sorter = 10
  pipeline.active = true

  pipeline.request_types << RequestType.find_by!(key: 'cherrypick')

  pipeline.workflow =
    Workflow
      .create!(name: 'Cherrypick')
      .tap do |workflow|
        # NOTE[xxx]: Note that the order here, and 'Set Location' being interactive, do not mimic the behaviour of
        # production
        [
          { class: PlateTemplateTask, name: 'Select Plate Template', sorted: 1, batched: true, lab_activity: true },
          { class: CherrypickTask, name: 'Approve Plate Layout', sorted: 2, batched: true, lab_activity: true }
        ].each { |details| details.delete(:class).create!(details.merge(workflow:)) }
      end
end

# Pulldown pipelines
pulldown_variants = %w[WGS SC ISC]
['Pulldown', 'Illumina-A Pulldown'].each do |lab|
  pulldown_variants.each do |pipeline_type|
    pipeline_name = "#{lab} #{pipeline_type}"
    Pipeline.create!(name: pipeline_name) do |pipeline|
      pipeline.sorter = Pipeline.maximum(:sorter) + 1

      pipeline.active = true
      pipeline.externally_managed = true

      pipeline.request_types << RequestType.create!(name: pipeline_name) do |request_type|
        request_type.billable = true
        request_type.key = pipeline_name.downcase.underscore.gsub(/\s+/, '_')
        request_type.initial_state = 'pending'
        request_type.asset_type = 'Well'
        request_type.target_purpose = Purpose.find_by(name: 'Legacy MX tube')
        request_type.order = 1
        request_type.multiples_allowed = false
        request_type.request_class = "Pulldown::Requests::#{pipeline_type.humanize}LibraryRequest".constantize
        request_type.for_multiplexing = true
      end

      pipeline.workflow = Workflow.create!(name: pipeline_name)
    end
  end
end

SequencingPipeline
  .create!(name: 'MiSeq sequencing') do |pipeline|
    pipeline.sorter = 2
    pipeline.active = true

    pipeline.request_types << RequestType.create!(key: 'miseq_sequencing', name: 'MiSeq sequencing') do |request_type|
      request_type.initial_state = 'pending'
      request_type.asset_type = 'LibraryTube'
      request_type.order = 1
      request_type.multiples_allowed = false
      request_type.request_class_name = MiSeqSequencingRequest.name
    end

    %w[a b c].each do |pl|
      pipeline.request_types << RequestType.create!(
        key: "illumina_#{pl}_miseq_sequencing",
        name: "Illumina-#{pl.upcase} MiSeq sequencing"
      ) do |request_type|
        request_type.initial_state = 'pending'
        request_type.asset_type = 'LibraryTube'
        request_type.order = 1
        request_type.multiples_allowed = false
        request_type.request_class_name = MiSeqSequencingRequest.name
      end
    end

    pipeline.workflow =
      Workflow
        .create!(name: 'MiSeq sequencing') do |workflow|
          workflow.locale = 'External'
          workflow.item_limit = 1
        end
        .tap do |workflow|
          t1 = SetDescriptorsTask.create!(name: 'Specify Dilution Volume', sorted: 0, workflow: workflow)
          Descriptor.create!(kind: 'Text', sorter: 1, name: 'Concentration', task: t1)
          t2 = SetDescriptorsTask.create!(name: 'Cluster Generation', sorted: 0, workflow: workflow)
          Descriptor.create!(kind: 'Text', sorter: 1, name: 'Chip barcode', task: t2)
          Descriptor.create!(kind: 'Text', sorter: 2, name: 'Cartridge barcode', task: t2)
          Descriptor.create!(kind: 'Text', sorter: 4, name: 'Machine name', task: t2)
        end
  end
  .tap do |pipeline|
    create_request_information_types(
      pipeline,
      'fragment_size_required_from',
      'fragment_size_required_to',
      'library_type',
      'read_length'
    )
  end

# ADD ILC Cherrypick
cprt =
  RequestType.create!(
    key: 'illumina_c_cherrypick',
    name: 'Illumina-C Cherrypick',
    asset_type: 'Well',
    order: 2,
    initial_state: 'pending',
    target_asset_type: 'Well',
    request_class_name: 'Request'
  )

liw = Workflow.create!(name: 'Illumina-C Cherrypick')

Workflow
  .find_by(name: 'Cherrypick')
  .tasks
  .each do |task|
    # next if task.name == 'Set Location'
    new_task = task.dup
    new_task.workflow = liw
    new_task.save!
  end

CherrypickPipeline.create!(
  name: 'Illumina-C Cherrypick',
  active: true,
  group_name: 'Illumina-C Library creation',
  max_size: 3000,
  sorter: 10,
  request_types: [cprt],
  workflow: liw,
  &:add_control_request_type
)

## Fluidigm Stuff

shared_options = { asset_type: 'Well', target_asset_type: 'Well', initial_state: 'pending' }

RequestType
  .create!(
    shared_options.merge(
      key: 'pick_to_sta',
      name: 'Pick to STA',
      order: 1,
      request_class_name: 'CherrypickForPulldownRequest'
    )
  )
  .tap { |rt| rt.acceptable_purposes << Purpose.find_by!(name: 'Working Dilution') }
RequestType
  .create!(
    shared_options.merge(
      key: 'pick_to_sta2',
      name: 'Pick to STA2',
      order: 2,
      request_class_name: 'CherrypickForPulldownRequest'
    )
  )
  .tap { |rt| rt.acceptable_purposes << Purpose.find_by!(name: 'STA') }
RequestType
  .create!(
    shared_options.merge(
      key: 'pick_to_fluidigm',
      name: 'Pick to Fluidigm',
      order: 3,
      request_class_name: 'CherrypickForFluidigmRequest'
    )
  )
  .tap { |rt| rt.acceptable_purposes << Purpose.find_by!(name: 'STA2') }
RequestType
  .create!(
    asset_type: 'Well',
    target_asset_type: 'Well',
    initial_state: 'pending',
    key: 'pick_to_snp_type',
    name: 'Pick to SNP Type',
    order: 3,
    request_class_name: 'CherrypickForPulldownRequest'
  )
  .tap { |rt| rt.acceptable_purposes << Purpose.find_by!(name: 'SNP Type') }

liw = Workflow.create!(name: 'Cherrypick for Fluidigm')

FluidigmTemplateTask.create!(
  name: 'Select Plate Template',
  pipeline_workflow_id: liw.id,
  sorted: 1,
  batched: true,
  lab_activity: true
)
CherrypickTask.create!(
  name: 'Approve Plate Layout',
  pipeline_workflow_id: liw.id,
  sorted: 2,
  batched: true,
  lab_activity: true
)

CherrypickPipeline.create!(
  name: 'Cherrypick for Fluidigm',
  active: true,
  sorter: 11,
  summary: true,
  group_name: 'Sample Logistics',
  workflow: liw,
  request_types: RequestType.where(key: %w[pick_to_sta pick_to_sta2 pick_to_snp_type pick_to_fluidigm]),
  control_request_type_id: 0,
  max_size: 192
) { |pipeline| }

v4_requests_types_pe =
  %w[a b c].map do |pipeline|
    RequestType.create!(
      key: "illumina_#{pipeline}_hiseq_v4_paired_end_sequencing",
      name: "Illumina-#{pipeline.upcase} HiSeq V4 Paired end sequencing",
      asset_type: 'LibraryTube',
      order: 2,
      initial_state: 'pending',
      request_class_name: 'HiSeqSequencingRequest',
      billable: true,
      product_line: ProductLine.find_by(name: "Illumina-#{pipeline.upcase}")
    )
  end

v4_requests_types_se = [
  RequestType.create!(
    key: 'illumina_c_hiseq_v4_single_end_sequencing',
    name: 'Illumina-C HiSeq V4 Single end sequencing',
    asset_type: 'LibraryTube',
    order: 2,
    initial_state: 'pending',
    request_class_name: 'HiSeqSequencingRequest',
    billable: true,
    product_line: ProductLine.find_by(name: 'Illumina-C')
  )
]

x10_requests_types =
  %w[a b].map do |pipeline|
    RequestType.create!(
      key: "illumina_#{pipeline}_hiseq_x_paired_end_sequencing",
      name: "Illumina-#{pipeline.upcase} HiSeq X Paired end sequencing",
      asset_type: 'LibraryTube',
      order: 2,
      initial_state: 'pending',
      request_class_name: 'HiSeqSequencingRequest',
      billable: true,
      product_line: ProductLine.find_by(name: "Illumina-#{pipeline.upcase}")
    )
  end << RequestType.create!(
    key: 'bespoke_hiseq_x_paired_end_sequencing',
    name: 'Bespoke HiSeq X Paired end sequencing',
    asset_type: 'LibraryTube',
    order: 2,
    initial_state: 'pending',
    request_class_name: 'HiSeqSequencingRequest',
    billable: true,
    product_line: ProductLine.find_by(name: 'Illumina-C')
  )

['(spiked in controls)', '(no controls)'].each do |type|
  SequencingPipeline.create!(
    name: "HiSeq v4 PE #{type}",
    active: true,
    sorter: 9,
    max_size: 8,
    min_size: 8,
    summary: true,
    group_name: 'Sequencing',
    control_request_type_id: 0
  ) do |pipeline|
    pipeline.workflow =
      Workflow
        .create!(name: pipeline.name) do |workflow|
          workflow.locale = 'Internal'
          workflow.item_limit = 8
        end
        .tap do |workflow|
          [
            { class: SetDescriptorsTask, name: 'Specify Dilution Volume', sorted: 1, batched: true },
            { class: SetDescriptorsTask, name: 'Cluster generation', sorted: 3, batched: true, lab_activity: true },
            {
              class: AddSpikedInControlTask,
              name: 'Add Spiked in Control',
              sorted: 4,
              batched: true,
              lab_activity: true
            },
            { class: SetDescriptorsTask, name: 'Quality control', sorted: 5, batched: true, lab_activity: true },
            {
              class: SetDescriptorsTask,
              name: 'Read 1 Lin/block/hyb/load',
              sorted: 6,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Read 2 Cluster/Lin/block/hyb/load',
              sorted: 7,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            }
          ].select { |task| type == '(spiked in controls)' || task[:name] != 'Add Spiked in Control' }
            .each { |details| details.delete(:class).create!(details.merge(workflow:)) }
        end
    pipeline.request_types = v4_requests_types_pe
  end

  SequencingPipeline.create!(
    name: "HiSeq v4 SE #{type}",
    active: true,
    sorter: 9,
    max_size: 8,
    min_size: 8,
    summary: true,
    group_name: 'Sequencing',
    control_request_type_id: 0
  ) do |pipeline|
    pipeline.workflow =
      Workflow
        .create!(name: pipeline.name) do |workflow|
          workflow.locale = 'Internal'
          workflow.item_limit = 8
        end
        .tap do |workflow|
          [
            { class: SetDescriptorsTask, name: 'Specify Dilution Volume', sorted: 1, batched: true },
            { class: SetDescriptorsTask, name: 'Cluster generation', sorted: 3, batched: true, lab_activity: true },
            {
              class: AddSpikedInControlTask,
              name: 'Add Spiked in Control',
              sorted: 4,
              batched: true,
              lab_activity: true
            },
            { class: SetDescriptorsTask, name: 'Quality control', sorted: 5, batched: true, lab_activity: true },
            {
              class: SetDescriptorsTask,
              name: 'Read 1 Lin/block/hyb/load',
              sorted: 6,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            }
          ].select { |task| type == '(spiked in controls)' || task[:name] != 'Add Spiked in Control' }
            .each { |details| details.delete(:class).create!(details.merge(workflow:)) }
        end
    pipeline.request_types = v4_requests_types_se
  end

  SequencingPipeline.create!(
    name: "HiSeq X PE #{type}",
    active: true,
    sorter: 9,
    max_size: 8,
    min_size: 8,
    summary: true,
    group_name: 'Sequencing',
    control_request_type_id: 0
  ) do |pipeline|
    pipeline.workflow =
      Workflow
        .create!(name: pipeline.name) do |workflow|
          workflow.locale = 'Internal'
          workflow.item_limit = 8
        end
        .tap do |workflow|
          [
            { class: SetDescriptorsTask, name: 'Specify Dilution Volume', sorted: 1, batched: true },
            { class: SetDescriptorsTask, name: 'Cluster generation', sorted: 3, batched: true, lab_activity: true },
            {
              class: AddSpikedInControlTask,
              name: 'Add Spiked in Control',
              sorted: 4,
              batched: true,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Read 1 Lin/block/hyb/load',
              sorted: 6,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            },
            {
              class: SetDescriptorsTask,
              name: 'Read 2 Cluster/Lin/block/hyb/load',
              sorted: 7,
              batched: true,
              interactive: true,
              per_item: true,
              lab_activity: true
            }
          ].select { |task| type == '(spiked in controls)' || task[:name] != 'Add Spiked in Control' }
            .each { |details| details.delete(:class).create!(details.merge(workflow:)) }
        end
    pipeline.request_types = x10_requests_types
  end
end

%w[htp c].each do |pipeline|
  RequestType
    .create!(
      key: "illumina_#{pipeline}_hiseq_4000_paired_end_sequencing",
      name: "Illumina-#{pipeline.upcase} HiSeq 4000 Paired end sequencing",
      asset_type: 'LibraryTube',
      order: 2,
      initial_state: 'pending',
      request_class_name: 'HiSeqSequencingRequest',
      billable: true,
      product_line: ProductLine.find_by(name: "Illumina-#{pipeline.upcase}"),
      request_purpose: :standard
    )
    .tap do |rt|
      RequestType::Validator.create!(request_type: rt, request_option: 'read_length', valid_options: [150, 75])
    end
  RequestType
    .create!(
      key: "illumina_#{pipeline}_hiseq_4000_single_end_sequencing",
      name: "Illumina-#{pipeline.upcase} HiSeq 4000 Single end sequencing",
      asset_type: 'LibraryTube',
      order: 2,
      initial_state: 'pending',
      request_class_name: 'HiSeqSequencingRequest',
      billable: true,
      product_line: ProductLine.find_by(name: "Illumina-#{pipeline.upcase}"),
      request_purpose: :standard
    )
    .tap { |rt| RequestType::Validator.create!(request_type: rt, request_option: 'read_length', valid_options: [50]) }
end

def build_4000_tasks_for(workflow, paired_only = false) # rubocop:todo Metrics/MethodLength
  AddSpikedInControlTask.create!(name: 'Add Spiked in control', sorted: 0, workflow: workflow)
  SetDescriptorsTask.create!(name: 'Cluster Generation', sorted: 1, workflow: workflow) do |task|
    task.descriptors.build(
      [
        { kind: 'Text', sorter: 1, name: 'Chip Barcode', required: true },
        { kind: 'Text', sorter: 3, name: 'Pipette Carousel #' },
        { kind: 'Text', sorter: 4, name: 'CBOT' },
        { kind: 'Text', sorter: 5, name: '-20 Temp. Read 1 Cluster Kit (Box 1 of 2) Lot #' },
        { kind: 'Text', sorter: 6, name: '-20 Temp. Read 1 Cluster Kit (Box 1 of 2) RGT #' },
        { kind: 'Text', sorter: 7, name: 'PhiX lot #' },
        { kind: 'Text', sorter: 8, name: 'Comment' }
      ]
    )
  end

  SetDescriptorsTask.create!(name: 'Read 1 Lin/block/hyb/load', sorted: 2, workflow: workflow) do |task|
    task.descriptors.build(
      [
        { kind: 'Text', sorter: 1, name: 'Chip Barcode', required: true },
        { kind: 'Text', sorter: 3, name: 'Pipette Carousel #' },
        { kind: 'Text', sorter: 4, name: 'Sequencing Machine' },
        { kind: 'Text', sorter: 5, name: '-20 SBS Kit lot #' },
        { kind: 'Text', sorter: 6, name: '-20 SBS Kit RGT #' },
        { kind: 'Text', sorter: 7, name: '+4 SBS Kit lot #' },
        { kind: 'Text', sorter: 8, name: '+4 SBS Kit RGT #' },
        { kind: 'Text', sorter: 9, name: 'Incorporation Mix (HIM)' },
        { kind: 'Text', sorter: 10, name: 'SBS Buffer 1 (HB1)' },
        { kind: 'Text', sorter: 11, name: 'Scan Mix (HSM)' },
        { kind: 'Text', sorter: 12, name: 'SBS Buffer 2 (HB2)' },
        { kind: 'Text', sorter: 13, name: 'Cleavage Mix (HCM)' },
        { kind: 'Text', sorter: 14, name: 'iPCR batch #' },
        { kind: 'Text', sorter: 15, name: 'Comment' }
      ]
    )
  end

  SetDescriptorsTask.create!(name: 'Read 2 Lin/block/hyb/load', sorted: 2, workflow: workflow) do |task|
    if paired_only
      task.descriptors.build(
        [
          { kind: 'Text', sorter: 2, name: 'Pipette Carousel #' },
          { kind: 'Text', sorter: 3, name: '-20 Temp. Read 2 Cluster Kit (Box 2 of 2) Lot #' },
          { kind: 'Text', sorter: 4, name: '-20 Temp. Read 2 Cluster Kit (Box 2 of 2) RGT #' },
          { kind: 'Text', sorter: 5, name: 'Resynthesis Mix (HRM)' },
          { kind: 'Text', sorter: 6, name: 'Linearization Mix 2 (HLM2)' },
          { kind: 'Text', sorter: 7, name: 'Amplification Mix (HAM)' },
          { kind: 'Text', sorter: 8, name: 'AMP premix (HPM)' },
          { kind: 'Text', sorter: 9, name: 'Denaturation Mix (HDR)' },
          { kind: 'Text', sorter: 10, name: 'Primer Mix Read 2 (HP11)' },
          { kind: 'Text', sorter: 11, name: 'Indexing Primer Mix (HP14)' },
          { kind: 'Text', sorter: 12, name: 'Comments' }
        ]
      )
    else
      task.descriptors.build(
        [
          { kind: 'Text', sorter: 2, name: 'Pipette Carousel #' },
          { kind: 'Text', sorter: 3, name: '-20 Temp. Read 1 Cluster Kit Lot #' },
          { kind: 'Text', sorter: 4, name: '-20 Temp. Read 1 Cluster Kit RGT #' },
          { kind: 'Text', sorter: 5, name: 'Resynthesis Mix (HRM)' },
          { kind: 'Text', sorter: 6, name: 'Denaturation Mix (HDR)' },
          { kind: 'Text', sorter: 7, name: 'Index 1 Primer Mix (HP12)' },
          { kind: 'Text', sorter: 8, name: 'Comments' }
        ]
      )
    end
  end
end

def add_4000_information_types_to(pipeline)
  pipeline.request_information_types << RequestInformationType.where(label: 'Vol.', hide_in_inbox: false).first!
  pipeline.request_information_types << RequestInformationType.where(label: 'Read length', hide_in_inbox: false).first!
end

SequencingPipeline.create!(
  name: 'HiSeq 4000 PE (spiked in controls)',
  active: true,
  sorter: 10,
  max_size: 8,
  group_name: 'Sequencing',
  control_request_type_id: 0,
  min_size: 8
) do |pipeline|
  pipeline.request_types = RequestType.where("`key` LIKE 'illumina_%_hiseq_4000_paired_end_sequencing'")
  pipeline.build_workflow(name: 'HiSeq 4000 PE').tap { |wf| build_4000_tasks_for(wf, true) }
  add_4000_information_types_to(pipeline)
end

SequencingPipeline.create!(
  name: 'HiSeq 4000 SE (spiked in controls)',
  active: true,
  sorter: 10,
  max_size: 8,
  group_name: 'Sequencing',
  control_request_type_id: 0,
  min_size: 8
) do |pipeline|
  pipeline.request_types = RequestType.where("`key` LIKE 'illumina_%_hiseq_4000_single_end_sequencing'")
  pipeline.build_workflow(name: 'HiSeq 4000 SE').tap { |wf| build_4000_tasks_for(wf) }
  add_4000_information_types_to(pipeline)
end

RequestType.find_each do |request_type|
  read_lengths =
    {
      # By request class
      'HiSeqSequencingRequest' => [50, 75, 100, 150],
      'MiSeqSequencingRequest' => [25, 50, 130, 150, 250, 300],
      'SequencingRequest' => [37, 54, 76, 108]
    }[
      request_type.request_class_name
    ]

  if read_lengths.present?
    RequestType::Validator.create!(
      request_type: request_type,
      request_option: 'read_length',
      valid_options: read_lengths
    )
  end
end
