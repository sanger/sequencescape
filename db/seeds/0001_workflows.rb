# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

require 'control_request_type_creation'

Pipeline.send(:include, ControlRequestTypeCreation)
Pipeline.send(:before_save, :add_control_request_type)

RequestType.send(:include, RequestTypePurposeCreation)
RequestType.send(:before_validation, :add_request_purpose)

ProductLine.create(name: 'Illumina-A')
ProductLine.create(name: 'Illumina-B')
ProductLine.create(name: 'Illumina-C')
ProductLine.create(name: 'Illumina-HTP')

##################################################################################################################
# Submission workflows and their associated pipelines.
##################################################################################################################
# There is a common pattern to create a Submission::Workflow and it's supporting entities.  You can pretty much copy
# this structure and replace the appropriate values:
#
#   submission_workflow = Submission::Workflow.create! do |workflow|
#     # Update workflow attributes here
#   end
#   LabInterface::Workflow.create!(:name => XXXX) do |workflow|
#     workflow.pipeline = PipelineClass.create!(:name => XXXX) do |pipeline|
#       # Set the Pipeline attributes here
#
#       pipeline.location = Location.where(:name => YYYY).first or raise StandardError, "Cannot find 'YYYY' location'
#       pipeline.request_types << RequestType.create!(:workflow => submission_workflow, :key => xxxx, :name => XXXX) do |request_type|
#         # Set the RequestType attributes here
#       end
#     end
#   end.tap do |workflow|
#     # Setup tasks for your LabInterface::Workflow here
#   end
#
# That should be enough for you to work out what you need to do.

# Utility method for getting a sequence of Pipeline instances to flow properly.  Call with a Hash mapping the
# flow from left to right, if you get what I mean!
def set_pipeline_flow_to(sequence)
  sequence.each do |current_name, next_name|
    current_pipeline, next_pipeline = [current_name, next_name].map { |name| Pipeline.find_by(name: name) or raise "Cannot find pipeline '#{name}'" }
    current_pipeline.update_attribute(:next_pipeline_id, next_pipeline.id)
    next_pipeline.update_attribute(:previous_pipeline_id, current_pipeline.id)
  end
end

locations_data = [
  'Library creation freezer',
  'Cluster formation freezer',
  'Sample logistics freezer',
  'Genotyping freezer',
  'Pulldown freezer',
  'PacBio library prep freezer',
  'PacBio sequencing freezer',
  'Illumina high throughput freezer'
]
locations_data.each do |location|
  Location.create!(name: location)
end
# import [ :name ], locations_data, :validate => false

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
  RequestInformationType.create!(
    name: data[0],
    key: data[1],
    label: data[2],
    hide_in_inbox: data[3]
  )
end

REQUEST_INFORMATION_TYPES = Hash[RequestInformationType.all.map { |t| [t.key, t] }].freeze
def create_request_information_types(pipeline, *keys)
  PipelineRequestInformationType.create!(keys.map { |k| { pipeline: pipeline, request_information_type: REQUEST_INFORMATION_TYPES[k] } })
end

##################################################################################################################
# Next-gen sequencing
##################################################################################################################
next_gen_sequencing = Submission::Workflow.create! do |workflow|
  workflow.key        = 'short_read_sequencing'
  workflow.name       = 'Next-gen sequencing'
  workflow.item_label = 'library'
end

LibraryCreationPipeline.create!(name: 'Illumina-C Library preparation') do |pipeline|
  pipeline.asset_type = 'LibraryTube'
  pipeline.sorter     = 0
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.find_by(name: 'Library creation freezer') or raise StandardError, "Cannot find 'Library creation freezer' location"

  pipeline.request_types << RequestType.create!(workflow: next_gen_sequencing, key: 'library_creation', name: 'Library creation',
                                                deprecated: true) do |request_type|
    request_type.billable           = true
    request_type.initial_state      = 'pending'
    request_type.asset_type         = 'SampleTube'
    request_type.order              = 1
    request_type.multiples_allowed  = false
    request_type.request_class_name = LibraryCreationRequest.name
  end << RequestType.create!(workflow: next_gen_sequencing, key: 'illumina_c_library_creation', name: 'Illumina-C Library creation',
                             product_line: ProductLine.find_by(name: 'Illumina-C')) do |request_type|
    request_type.billable           = true
    request_type.initial_state      = 'pending'
    request_type.asset_type         = 'SampleTube'
    request_type.order              = 1
    request_type.multiples_allowed  = false
    request_type.request_class_name = LibraryCreationRequest.name
         end

  pipeline.workflow = LabInterface::Workflow.create!(name: 'Library preparation') do |workflow|
    workflow.locale = 'External'
  end.tap do |workflow|
    fragment_family = Family.create!(name: 'Fragment', description: 'Archived fragment')
    Descriptor.create!(name: 'start', family_id: fragment_family.id)

    [
      { class: SetDescriptorsTask, name: 'Initial QC',       sorted: 1, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Gel',              sorted: 2, interactive: false, per_item: false, families: [fragment_family], lab_activity: true },
      { class: SetDescriptorsTask, name: 'Characterisation', sorted: 3, batched: true, interactive: false, per_item: false, lab_activity: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'fragment_size_required_from', 'fragment_size_required_to', 'library_type')
end

MultiplexedLibraryCreationPipeline.create!(name: 'Illumina-B MX Library Preparation') do |pipeline|
  pipeline.asset_type          = 'LibraryTube'
  pipeline.sorter              = 0
  pipeline.automated           = false
  pipeline.active              = true
  pipeline.multiplexed         = true

  pipeline.location = Location.find_by(name: 'Library creation freezer') or raise StandardError, "Cannot find 'Library creation freezer' location"

  pipeline.request_types << RequestType.create!(
    workflow: next_gen_sequencing,
    key: 'multiplexed_library_creation',
    name: 'Multiplexed library creation'
  ) do |request_type|
    request_type.billable          = true
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'SampleTube'
    request_type.order             = 1
    request_type.multiples_allowed = false
    request_type.request_class     = MultiplexedLibraryCreationRequest
    request_type.for_multiplexing  = true
  end

  pipeline.request_types << RequestType.create!(
    workflow: Submission::Workflow.find_by(key: 'short_read_sequencing'),
    key: 'illumina_b_multiplexed_library_creation',
    name: 'Illumina-B Multiplexed Library Creation',
    product_line: ProductLine.find_by(name: 'Illumina-B'),
    deprecated: true
  ) do |request_type|
    request_type.billable          = true
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'SampleTube'
    request_type.order             = 1
    request_type.multiples_allowed = false
    request_type.request_class     = MultiplexedLibraryCreationRequest
    request_type.for_multiplexing  = true
  end

  pipeline.workflow = LabInterface::Workflow.create!(name: 'Illumina-B MX Library Preparation') do |workflow|
    workflow.locale = 'External'
  end.tap do |workflow|
    [
      { class: TagGroupsTask,      name: 'Tag Groups',       sorted: 1, lab_activity: true },
      { class: AssignTagsTask,     name: 'Assign Tags',      sorted: 2, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Initial QC',       sorted: 3, batched: false, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Gel',              sorted: 4, batched: false, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Characterisation', sorted: 5, batched: true, lab_activity: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'fragment_size_required_from', 'fragment_size_required_to', 'read_length', 'library_type')
  PipelineRequestInformationType.create!(pipeline: pipeline, request_information_type: RequestInformationType.find_by(label: 'Concentration'))
end

MultiplexedLibraryCreationPipeline.create!(name: 'Illumina-C MX Library Preparation') do |pipeline|
  pipeline.asset_type  = 'LibraryTube'
  pipeline.sorter      = 0
  pipeline.automated   = false
  pipeline.active      = true
  pipeline.multiplexed = true
  pipeline.group_name  = 'Library creation'

  pipeline.location = Location.find_by(name: 'Library creation freezer') or raise StandardError, "Cannot find 'Library creation freezer' location"

  pipeline.request_types << RequestType.create!(
    workflow: Submission::Workflow.find_by(key: 'short_read_sequencing'),
    key: 'illumina_c_multiplexed_library_creation',
    name: 'Illumina-C Multiplexed Library Creation',
    product_line: ProductLine.find_by(name: 'Illumina-C')
  ) do |request_type|
    request_type.billable          = true
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'SampleTube'
    request_type.order             = 1
    request_type.multiples_allowed = false
    request_type.request_class     = MultiplexedLibraryCreationRequest
    request_type.for_multiplexing  = true
  end

  pipeline.workflow = LabInterface::Workflow.create!(name: 'Illumina-C MX Library Preparation workflow') do |workflow|
    workflow.locale = 'External'
  end.tap do |workflow|
    {
      TagGroupsTask      => { name: 'Tag Groups',       sorted: 1, lab_activity: true },
      AssignTagsTask     => { name: 'Assign Tags',      sorted: 2, lab_activity: true },
      SetDescriptorsTask => { name: 'Initial QC',       sorted: 3, batched: false, lab_activity: true },
      SetDescriptorsTask => { name: 'Gel',              sorted: 4, batched: false, lab_activity: true },
      SetDescriptorsTask => { name: 'Characterisation', sorted: 5, batched: true, lab_activity: true }
    }.each do |klass, details|
      klass.create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(
    pipeline,
    'fragment_size_required_from',
    'fragment_size_required_to',
    'read_length',
    'library_type'
  )

  PipelineRequestInformationType.create!(
    pipeline: pipeline,
    request_information_type: RequestInformationType.find_by(label: 'Concentration')
  )
end

PulldownLibraryCreationPipeline.create!(name: 'Pulldown library preparation') do |pipeline|
  pipeline.asset_type = 'LibraryTube'
  pipeline.sorter     = 12
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.find_by(name: 'Library creation freezer') or raise StandardError, "Cannot find 'Library creation freezer' location"

  pipeline.request_types << RequestType.create!(workflow: next_gen_sequencing, key: 'pulldown_library_creation', name: 'Pulldown library creation') do |request_type|
    request_type.billable          = true
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'SampleTube'
    request_type.order             = 1
    request_type.multiples_allowed = false
    request_type.request_class = LibraryCreationRequest
  end

  pipeline.workflow = LabInterface::Workflow.create!(name: 'Pulldown library preparation') do |workflow|
    workflow.locale = 'External'
  end.tap do |workflow|
    [
      { class: SetDescriptorsTask, name: 'Shearing',               sorted: 1, batched: false, interactive: true, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Library preparation',    sorted: 2, batched: false, interactive: true, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Pre-hybridisation PCR',  sorted: 3, batched: false, interactive: true, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Hybridisation',          sorted: 4, batched: false, interactive: true, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Post-hybridisation PCR', sorted: 5, batched: false, interactive: true, lab_activity: true },
      { class: SetDescriptorsTask, name: 'qPCR',                   sorted: 6, batched: false, interactive: true, lab_activity: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end

cluster_formation_se_request_type = ['a', 'b', 'c'].map do |pl|
  RequestType.create!(
    workflow: next_gen_sequencing,
    key: "illumina_#{pl}_single_ended_sequencing",
    name: "Illumina-#{pl.upcase} Single ended sequencing",
    product_line: ProductLine.find_by(name: "Illumina-#{pl.upcase}")) do |request_type|
    request_type.billable          = true
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'LibraryTube'
    request_type.order             = 2
    request_type.multiples_allowed = true
    request_type.request_class = SequencingRequest
  end
end << RequestType.create!(
    workflow: next_gen_sequencing,
    key: 'single_ended_sequencing',
    name: 'Single ended sequencing',
    deprecated: true
  ) do |request_type|
    request_type.billable          = true
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'LibraryTube'
    request_type.order             = 2
    request_type.multiples_allowed = true
    request_type.request_class = SequencingRequest
  end

SequencingPipeline.create!(name: 'Cluster formation SE (spiked in controls)', request_types: cluster_formation_se_request_type) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 2
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.find_by(name: 'Cluster formation freezer') or raise StandardError, "Cannot find 'Cluster formation freezer' location"
  pipeline.workflow = LabInterface::Workflow.create!(name: 'Cluster formation SE (spiked in controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      # NOTE: Yes, there's a typo in the name here:
      { class: SetDescriptorsTask,     name: 'Specify Dilution Volume ',  sorted: 1, batched: true },
      { class: AddSpikedInControlTask, name: 'Add Spiked in Control',     sorted: 2, batched: true },

      { class: SetDescriptorsTask,     name: 'Cluster generation',        sorted: 4, batched: true, interactive: false, per_item: false, lab_activity: true },
      { class: SetDescriptorsTask,     name: 'Quality control',           sorted: 5, batched: true, interactive: false, per_item: false, lab_activity: true },
      { class: SetDescriptorsTask,     name: 'Lin/block/hyb/load',        sorted: 6, batched: true, interactive: false, per_item: false, lab_activity: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  PipelineRequestInformationType.create!(pipeline: pipeline, request_information_type: RequestInformationType.find_by(key: 'read_length'))
  PipelineRequestInformationType.create!(pipeline: pipeline, request_information_type: RequestInformationType.find_by(key: 'library_type'))
  PipelineRequestInformationType.create!(pipeline: pipeline, request_information_type: RequestInformationType.find_by(label: 'Vol.'))
end

SequencingPipeline.create!(name: 'Cluster formation SE', request_types: cluster_formation_se_request_type) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 2
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.find_by(name: 'Cluster formation freezer') or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(name: 'Cluster formation SE') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      # NOTE: Yes, there's a typo in the name here:
      { class: SetDescriptorsTask, name: 'Specify Dilution Volume ', sorted: 1, batched: true },

      { class: SetDescriptorsTask, name: 'Cluster generation',       sorted: 3, batched: true, interactive: false, per_item: false, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Quality control',          sorted: 4, batched: true, interactive: false, per_item: false, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Lin/block/hyb/load',       sorted: 5, batched: true, interactive: false, per_item: false, lab_activity: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'read_length', 'library_type')
  PipelineRequestInformationType.create!(pipeline: pipeline, request_information_type: RequestInformationType.find_by(label: 'Vol.'))
end

SequencingPipeline.create!(name: 'Cluster formation SE (no controls)', request_types: cluster_formation_se_request_type) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 2
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.find_by(name: 'Cluster formation freezer') or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(name: 'Cluster formation SE (no controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      # NOTE: Yes, there's a typo in the name here:
      { class: SetDescriptorsTask, name: 'Specify Dilution Volume ', sorted: 1, batched: true },

      { class: SetDescriptorsTask, name: 'Cluster generation',       sorted: 3, batched: true, interactive: false, per_item: false, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Quality control',          sorted: 4, batched: true, interactive: false, per_item: false, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Lin/block/hyb/load',       sorted: 5, batched: true, interactive: false, per_item: false, lab_activity: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'read_length', 'library_type')
  PipelineRequestInformationType.create!(pipeline: pipeline, request_information_type: RequestInformationType.find_by(label: 'Vol.'))
end

single_ended_hi_seq_sequencing = ['a', 'b', 'c'].map do |pl|
  RequestType.create!(workflow: next_gen_sequencing, key: "illumina_#{pl}_single_ended_hi_seq_sequencing", name: "Illumina-#{pl.upcase} Single ended hi seq sequencing", product_line: ProductLine.find_by(name: "Illumina-#{pl.upcase}")) do |request_type|
    request_type.billable          = true
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'LibraryTube'
    request_type.order             = 2
    request_type.multiples_allowed = true
    request_type.request_class = HiSeqSequencingRequest
  end
end << RequestType.create!(
    workflow: next_gen_sequencing,
    key: 'single_ended_hi_seq_sequencing',
    name: 'Single ended hi seq sequencing',
    deprecated: true
  ) do |request_type|
    request_type.billable          = true
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'LibraryTube'
    request_type.order             = 2
    request_type.multiples_allowed = true
    request_type.request_class = HiSeqSequencingRequest
  end

SequencingPipeline.create!(name: 'Cluster formation SE HiSeq', request_types: single_ended_hi_seq_sequencing) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 2
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.find_by(name: 'Cluster formation freezer') or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(name: 'Cluster formation SE HiSeq') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      # NOTE: Yes, there's a typo in the name here:
      { class: SetDescriptorsTask, name: 'Specify Dilution Volume ', sorted: 1, batched: true },

      { class: SetDescriptorsTask, name: 'Cluster generation',       sorted: 3, batched: true, interactive: false, per_item: false, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Quality control',          sorted: 4, batched: true, interactive: false, per_item: false, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Lin/block/hyb/load',       sorted: 5, batched: true, interactive: false, per_item: false, lab_activity: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'read_length', 'library_type')
  PipelineRequestInformationType.create!(pipeline: pipeline, request_information_type: RequestInformationType.find_by(label: 'Vol.'))
end

SequencingPipeline.create!(name: 'Cluster formation SE HiSeq (no controls)', request_types: single_ended_hi_seq_sequencing) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 2
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.find_by(name: 'Cluster formation freezer') or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(name: 'Cluster formation SE HiSeq (no controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      # NOTE: Yes, there's a typo in the name here:
      { class: SetDescriptorsTask, name: 'Specify Dilution Volume ', sorted: 1, batched: true },

      { class: SetDescriptorsTask, name: 'Cluster generation',       sorted: 3, batched: true, interactive: false, per_item: false, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Quality control',          sorted: 4, batched: true, interactive: false, per_item: false, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Lin/block/hyb/load',       sorted: 5, batched: true, interactive: false, per_item: false, lab_activity: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'read_length', 'library_type')
  PipelineRequestInformationType.create!(pipeline: pipeline, request_information_type: RequestInformationType.find_by(label: 'Vol.'))
end

cluster_formation_pe_request_types = ['a', 'b', 'c'].map do |pl|
  RequestType.create!(workflow: next_gen_sequencing, key: "illumina_#{pl}_paired_end_sequencing", name: "Illumina-#{pl.upcase} Paired end sequencing", product_line: ProductLine.find_by(name: "Illumina-#{pl.upcase}")) do |request_type|
    request_type.billable          = true
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'LibraryTube'
    request_type.order             = 2
    request_type.multiples_allowed = true
    request_type.request_class = SequencingRequest
  end
end << RequestType.create!(
    workflow: next_gen_sequencing,
    key: 'paired_end_sequencing',
    name: 'Paired end sequencing',
    deprecated: true
  ) do |request_type|
    request_type.billable          = true
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'LibraryTube'
    request_type.order             = 2
    request_type.multiples_allowed = true
    request_type.request_class = SequencingRequest
  end

hiseq_2500_request_types = ['a', 'b', 'c'].map do |pl|
  RequestType.create!(
    key: "illumina_#{pl}_hiseq_2500_paired_end_sequencing",
    name: "Illumina-#{pl.upcase} HiSeq 2500 Paired end sequencing",
    workflow: Submission::Workflow.find_by(key: 'short_read_sequencing'),
    asset_type: 'LibraryTube',
    order: 2,
    initial_state: 'pending',
    multiples_allowed: true,
    request_class_name: 'HiSeqSequencingRequest',
    product_line: ProductLine.find_by(name: "Illumina-#{pl.upcase}")
  )
end

hiseq_2500_se_request_types = ['a', 'b', 'c'].map do |pl|
  RequestType.create!(
    key: "illumina_#{pl}_hiseq_2500_single_end_sequencing",
    name: "Illumina-#{pl.upcase} HiSeq 2500 Single end sequencing",
    workflow: Submission::Workflow.find_by(key: 'short_read_sequencing'),
    asset_type: 'LibraryTube',
    order: 2,
    initial_state: 'pending',
    multiples_allowed: true,
    request_class_name: 'HiSeqSequencingRequest',
    product_line: ProductLine.find_by(name: "Illumina-#{pl.upcase}")
  )
end

SequencingPipeline.create!(name: 'Cluster formation PE', request_types: cluster_formation_pe_request_types) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 3
  pipeline.automated  = false
  pipeline.active     = true
  pipeline.location   = Location.find_by(name: 'Cluster formation freezer') or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(name: 'Cluster formation PE') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      { class: SetDescriptorsTask, name: 'Specify Dilution Volume',           sorted: 1, batched: true },

      { class: SetDescriptorsTask, name: 'Cluster generation',                sorted: 3, batched: true, interactive: false, per_item: false, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Quality control',                   sorted: 4, batched: true, interactive: false, per_item: false, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Read 1 Lin/block/hyb/load',         sorted: 5, batched: true, interactive: true, per_item: true, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Read 2 Cluster/Lin/block/hyb/load', sorted: 6, batched: true, interactive: true, per_item: true, lab_activity: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'read_length', 'library_type')
  PipelineRequestInformationType.create!(pipeline: pipeline, request_information_type: RequestInformationType.find_by(label: 'Vol.'))
end

SequencingPipeline.create!(name: 'Cluster formation PE (no controls)', request_types: cluster_formation_pe_request_types) do |pipeline|
  pipeline.asset_type      = 'Lane'
  pipeline.sorter          = 8
  pipeline.automated       = false
  pipeline.active          = true
  pipeline.group_by_parent = false
  pipeline.location        = Location.find_by(name: 'Cluster formation freezer') or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(name: 'Cluster formation PE (no controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      { class: SetDescriptorsTask, name: 'Specify Dilution Volume',           sorted: 1, batched: true },

      { class: SetDescriptorsTask, name: 'Cluster generation',                sorted: 3, batched: true, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Quality control',                   sorted: 4, batched: true, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Read 1 Lin/block/hyb/load',         sorted: 5, batched: true, interactive: true, per_item: true, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Read 2 Cluster/Lin/block/hyb/load', sorted: 6, batched: true, interactive: true, per_item: true, lab_activity: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'read_length', 'library_type')
end

SequencingPipeline.create!(name: 'Cluster formation PE (spiked in controls)', request_types: cluster_formation_pe_request_types) do |pipeline|
  pipeline.asset_type      = 'Lane'
  pipeline.sorter          = 8
  pipeline.automated       = false
  pipeline.active          = true
  pipeline.group_by_parent = false
  pipeline.location        = Location.find_by(name: 'Cluster formation freezer') or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(name: 'Cluster formation PE (spiked in controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      { class: SetDescriptorsTask,     name: 'Specify Dilution Volume',           sorted: 1, batched: true },

      { class: SetDescriptorsTask,     name: 'Cluster generation',                sorted: 3, batched: true, lab_activity: true },
      { class: AddSpikedInControlTask, name: 'Add Spiked in Control',             sorted: 4, batched: true, lab_activity: true },
      { class: SetDescriptorsTask,     name: 'Quality control',                   sorted: 5, batched: true, lab_activity: true },
      { class: SetDescriptorsTask,     name: 'Read 1 Lin/block/hyb/load',         sorted: 6, batched: true, interactive: true, per_item: true, lab_activity: true },
      { class: SetDescriptorsTask,     name: 'Read 2 Cluster/Lin/block/hyb/load', sorted: 7, batched: true, interactive: true, per_item: true, lab_activity: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'read_length', 'library_type')
  PipelineRequestInformationType.create!(pipeline: pipeline, request_information_type: RequestInformationType.find_by(label: 'Vol.'))
end

SequencingPipeline.create!(name: 'HiSeq Cluster formation PE (spiked in controls)', request_types: cluster_formation_pe_request_types) do |pipeline|
  pipeline.asset_type      = 'Lane'
  pipeline.sorter          = 9
  pipeline.automated       = false
  pipeline.active          = true
  pipeline.group_by_parent = false
  pipeline.location        = Location.find_by(name: 'Cluster formation freezer') or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(name: 'HiSeq Cluster formation PE (spiked in controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      { class: SetDescriptorsTask,     name: 'Specify Dilution Volume',           sorted: 1, batched: true },

      { class: SetDescriptorsTask,     name: 'Cluster generation',                sorted: 3, batched: true, lab_activity: true },
      { class: AddSpikedInControlTask, name: 'Add Spiked in Control',             sorted: 4, batched: true, lab_activity: true },
      { class: SetDescriptorsTask,     name: 'Quality control',                   sorted: 5, batched: true, lab_activity: true },
      { class: SetDescriptorsTask,     name: 'Read 1 Lin/block/hyb/load',         sorted: 6, batched: true, interactive: true, per_item: true, lab_activity: true },
      { class: SetDescriptorsTask,     name: 'Read 2 Cluster/Lin/block/hyb/load', sorted: 7, batched: true, interactive: true, per_item: true, lab_activity: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'read_length', 'library_type')
  PipelineRequestInformationType.create!(pipeline: pipeline, request_information_type: RequestInformationType.find_by(label: 'Vol.'))
end

SequencingPipeline.create!(name: 'HiSeq 2500 PE (spiked in controls)', request_types: hiseq_2500_request_types) do |pipeline|
  pipeline.asset_type      = 'Lane'
  pipeline.sorter          = 9
  pipeline.max_size        = 2
  pipeline.automated       = false
  pipeline.active          = true
  pipeline.group_by_parent = false
  pipeline.location        = Location.find_by(name: 'Cluster formation freezer') or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(name: 'HiSeq 2500 PE (spiked in controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 2
  end.tap do |workflow|
    [
      { class: SetDescriptorsTask,     name: 'Specify Dilution Volume', sorted: 1, batched: true },

      { class: AddSpikedInControlTask, name: 'Add Spiked in Control',   sorted: 3, batched: true, lab_activity: true },
      { class: SetDescriptorsTask,     name: 'Quality control',                   sorted: 4, batched: true, lab_activity: true },
      { class: SetDescriptorsTask,     name: 'Read 1 Lin/block/hyb/load',         sorted: 5, batched: true, interactive: true, per_item: true, lab_activity: true },
      { class: SetDescriptorsTask,     name: 'Read 2 Cluster/Lin/block/hyb/load', sorted: 6, batched: true, interactive: true, per_item: true, lab_activity: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'read_length', 'library_type')
  PipelineRequestInformationType.create!(pipeline: pipeline, request_information_type: RequestInformationType.find_by(label: 'Vol.'))
end

SequencingPipeline.create!(name: 'HiSeq 2500 SE (spiked in controls)', request_types: hiseq_2500_se_request_types) do |pipeline|
  pipeline.asset_type      = 'Lane'
  pipeline.sorter          = 9
  pipeline.max_size        = 2
  pipeline.automated       = false
  pipeline.active          = true
  pipeline.group_by_parent = false
  pipeline.location        = Location.find_by(name: 'Cluster formation freezer') or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(name: 'HiSeq 2500 SE (spiked in controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 2
  end.tap do |workflow|
    [
      { class: SetDescriptorsTask,     name: 'Specify Dilution Volume', sorted: 1, batched: true },

      { class: AddSpikedInControlTask, name: 'Add Spiked in Control',   sorted: 3, batched: true, lab_activity: true },
      { class: SetDescriptorsTask,     name: 'Quality control',         sorted: 4, batched: true, interactive: false, per_item: false, lab_activity: true },
      { class: SetDescriptorsTask,     name: 'Lin/block/hyb/load',      sorted: 5, batched: true, interactive: false, per_item: false, lab_activity: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'read_length', 'library_type')
  PipelineRequestInformationType.create!(pipeline: pipeline, request_information_type: RequestInformationType.find_by(label: 'Vol.'))
end

SequencingPipeline.create!(name: 'Cluster formation SE HiSeq (spiked in controls)', request_types: cluster_formation_pe_request_types) do |pipeline|
  pipeline.asset_type      = 'Lane'
  pipeline.sorter          = 8
  pipeline.automated       = false
  pipeline.active          = true
  pipeline.group_by_parent = false
  pipeline.location        = Location.find_by(name: 'Cluster formation freezer') or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(name: 'Cluster formation SE HiSeq (spiked in controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      { class: SetDescriptorsTask,     name: 'Specify Dilution Volume',           sorted: 1, batched: true },

      { class: SetDescriptorsTask,     name: 'Cluster generation',                sorted: 3, batched: true, lab_activity: true },
      { class: AddSpikedInControlTask, name: 'Add Spiked in Control',             sorted: 4, batched: true, lab_activity: true },
      { class: SetDescriptorsTask,     name: 'Quality control',                   sorted: 5, batched: true, lab_activity: true },
      { class: SetDescriptorsTask,     name: 'Read 1 Lin/block/hyb/load',         sorted: 6, batched: true, interactive: true, per_item: true, lab_activity: true },
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'read_length', 'library_type')
  PipelineRequestInformationType.create!(pipeline: pipeline, request_information_type: RequestInformationType.find_by(label: 'Vol.'))
end

# TODO: This pipeline has been cloned from the 'Cluster formation PE (no controls)'.  Needs checking
SequencingPipeline.create!(name: 'HiSeq Cluster formation PE (no controls)') do |pipeline|
  pipeline.asset_type      = 'Lane'
  pipeline.sorter          = 8
  pipeline.automated       = false
  pipeline.active          = true
  pipeline.group_by_parent = false
  pipeline.location        = Location.find_by(name: 'Cluster formation freezer') or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  ['a', 'b', 'c'].each do |pl|
    pipeline.request_types << RequestType.create!(workflow: next_gen_sequencing, key: "illumina_#{pl}_hiseq_paired_end_sequencing", name: "Illumina-#{pl.upcase} HiSeq Paired end sequencing", product_line: ProductLine.find_by(name: "Illumina-#{pl.upcase}")) do |request_type|
      request_type.billable          = true
      request_type.initial_state     = 'pending'
      request_type.asset_type        = 'LibraryTube'
      request_type.order             = 2
      request_type.multiples_allowed = true
      request_type.request_class = HiSeqSequencingRequest
    end
  end
  pipeline.request_types << RequestType.create!(
    workflow: next_gen_sequencing,
    key: 'hiseq_paired_end_sequencing',
    name: 'HiSeq Paired end sequencing',
    deprecated: true
  ) do |request_type|
    request_type.billable          = true
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'LibraryTube'
    request_type.order             = 2
    request_type.multiples_allowed = true
    request_type.request_class = HiSeqSequencingRequest
  end

  pipeline.workflow = LabInterface::Workflow.create!(name: 'HiSeq Cluster formation PE (no controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      { class: SetDescriptorsTask, name: 'Specify Dilution Volume',           sorted: 1, batched: true },

      { class: SetDescriptorsTask, name: 'Cluster generation',                sorted: 3, batched: true, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Quality control',                   sorted: 4, batched: true, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Read 1 Lin/block/hyb/load',         sorted: 5, batched: true, interactive: true, per_item: true, lab_activity: true },
      { class: SetDescriptorsTask, name: 'Read 2 Cluster/Lin/block/hyb/load', sorted: 6, batched: true, interactive: true, per_item: true, lab_activity: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'read_length', 'library_type')
  PipelineRequestInformationType.create!(pipeline: pipeline, request_information_type: RequestInformationType.find_by(label: 'Vol.'))
end

##################################################################################################################
# Microarray genotyping
##################################################################################################################
microarray_genotyping = Submission::Workflow.create! do |workflow|
  workflow.key        = 'microarray_genotyping'
  workflow.name       = 'Microarray genotyping'
  workflow.item_label = 'Run'
end

CherrypickPipeline.create!(name: 'Cherrypick') do |pipeline|
  pipeline.asset_type          = 'Well'
  pipeline.sorter              = 10
  pipeline.automated           = false
  pipeline.active              = true
  pipeline.group_by_parent     = true

  pipeline.location = Location.find_by(name: 'Sample logistics freezer') or raise StandardError, "Cannot find 'Sample logistics freezer' location"

  pipeline.request_types << RequestType.create!(workflow: microarray_genotyping, key: 'cherrypick', name: 'Cherrypick') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.target_asset_type = 'Well'
    request_type.asset_type        = 'Well'
    request_type.order             = 2
    request_type.request_class     = CherrypickForPulldownRequest
    request_type.multiples_allowed = false
  end

  pipeline.workflow = LabInterface::Workflow.create!(name: 'Cherrypick').tap do |workflow|
    # NOTE[xxx]: Note that the order here, and 'Set Location' being interactive, do not mimic the behaviour of production
    [
      { class: PlateTemplateTask,      name: 'Select Plate Template',              sorted: 1, batched: true, lab_activity: true },
      { class: CherrypickTask,         name: 'Approve Plate Layout',               sorted: 2, batched: true, lab_activity: true },
      { class: SetLocationTask,        name: 'Set Location',                       sorted: 4, lab_activity: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end

CherrypickForPulldownPipeline.create!(name: 'Cherrypicking for Pulldown') do |pipeline|
  pipeline.asset_type          = 'Well'
  pipeline.sorter              = 13
  pipeline.automated           = false
  pipeline.active              = true
  pipeline.group_by_parent     = true

  pipeline.location = Location.find_by(name: 'Sample logistics freezer') or raise StandardError, "Cannot find 'Sample logistics freezer' location"

  cherrypicking_attributes = lambda do |request_type|
    request_type.initial_state     = 'pending'
    request_type.target_asset_type = 'Well'
    request_type.asset_type        = 'Well'
    request_type.order             = 1
    request_type.request_class     = CherrypickForPulldownRequest
    request_type.multiples_allowed = false
    request_type.for_multiplexing  = false
  end

  pipeline.request_types << RequestType.create!(workflow: next_gen_sequencing, key: 'cherrypick_for_pulldown', name: 'Cherrypicking for Pulldown',  &cherrypicking_attributes)

  pipeline.request_types << RequestType.create!(workflow: next_gen_sequencing, key: 'cherrypick_for_illumina',   name: 'Cherrypick for Illumina',   &cherrypicking_attributes)
  pipeline.request_types << RequestType.create!(workflow: next_gen_sequencing, key: 'cherrypick_for_illumina_b', name: 'Cherrypick for Illumina-B', &cherrypicking_attributes)
  pipeline.request_types << RequestType.create!(workflow: next_gen_sequencing, key: 'cherrypick_for_illumina_c', name: 'Cherrypick for Illumina-C', &cherrypicking_attributes)

  pipeline.workflow = LabInterface::Workflow.create!(name: 'Cherrypicking for Pulldown').tap do |workflow|
    # NOTE[xxx]: Note that the order here, and 'Set Location' being interactive, do not mimic the behaviour of production
    [
      { class: CherrypickGroupBySubmissionTask, name: 'Cherrypick Group By Submission', sorted: 1, batched: true },
      { class: SetLocationTask,                 name: 'Set location', sorted: 2 }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end

DnaQcPipeline.create!(name: 'DNA QC') do |pipeline|
  pipeline.sorter              = 9
  pipeline.automated           = false
  pipeline.active              = true
  pipeline.group_by_parent     = true

  pipeline.location = Location.find_by(name: 'Sample logistics freezer') or raise StandardError, "Cannot find 'Sample logistics freezer' location"

  pipeline.request_types << RequestType.create!(workflow: microarray_genotyping, key: 'dna_qc', name: 'DNA QC', no_target_asset: true) do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'Well'
    request_type.order             = 1
    request_type.request_class     = QcRequest
    request_type.multiples_allowed = false
  end

  pipeline.workflow = LabInterface::Workflow.create!(name: 'DNA QC').tap do |workflow|
    [
      { class: DnaQcTask, name: 'QC result', sorted: 1, batched: false, interactive: false }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end

GenotypingPipeline.create!(name: 'Genotyping') do |pipeline|
  pipeline.sorter = 11
  pipeline.automated = false
  pipeline.active = true
  pipeline.group_by_parent = true

  pipeline.location = Location.find_by(name: 'Genotyping freezer') or raise StandardError, "Cannot find 'Genotyping freezer' location"

  pipeline.request_types << RequestType.create!(workflow: microarray_genotyping, key: 'genotyping', name: 'Genotyping') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'Well'
    request_type.order             = 3
    request_type.request_class     = GenotypingRequest
    request_type.multiples_allowed = false
  end

  pipeline.workflow = LabInterface::Workflow.create!(name: 'Genotyping').tap do |workflow|
    [
      { class: AttachInfiniumBarcodeTask, name: 'Attach Infinium Barcode', sorted: 1, batched: true },
      { class: GenerateManifestsTask,     name: 'Generate Manifests',      sorted: 2, batched: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end

PulldownMultiplexLibraryPreparationPipeline.create!(name: 'Pulldown Multiplex Library Preparation') do |pipeline|
  pipeline.asset_type           = 'Well'
  pipeline.sorter               = 14
  pipeline.automated            = false
  pipeline.active               = true
  pipeline.group_by_parent      = true
  pipeline.max_size             = 96
  pipeline.max_number_of_groups = 1

  pipeline.location = Location.find_by(name: 'Pulldown freezer') or raise StandardError, "Cannot find 'Pulldown freezer' location"

  pipeline.request_types << RequestType.create!(workflow: next_gen_sequencing, key: 'pulldown_multiplexing', name: 'Pulldown Multiplex Library Preparation') do |request_type|
    request_type.billable          = true
    request_type.asset_type        = 'Well'
    request_type.target_asset_type = 'PulldownMultiplexedLibraryTube'
    request_type.order             = 1
    request_type.request_class     = PulldownMultiplexedLibraryCreationRequest
    request_type.multiples_allowed = false
    request_type.for_multiplexing  = true
  end

  pipeline.workflow = LabInterface::Workflow.create!(name: 'Pulldown Multiplex Library Preparation').tap do |workflow|
    [
      { class: TagGroupsTask,         name: 'Tag Groups',           sorted: 1 },
      { class: AssignTagsToWellsTask, name: 'Assign Tags to Wells', sorted: 2 }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end

set_pipeline_flow_to('Cherrypicking for Pulldown' => 'Pulldown Multiplex Library Preparation')
set_pipeline_flow_to('DNA QC' => 'Cherrypick')

PacBioSamplePrepPipeline.create!(name: 'PacBio Library Prep') do |pipeline|
  pipeline.sorter               = 14
  pipeline.automated            = false
  pipeline.active               = true
  pipeline.asset_type           = 'PacBioLibraryTube'
  pipeline.group_by_parent      = true

  pipeline.location = Location.find_by(name: 'PacBio library prep freezer') or raise StandardError, "Cannot find 'PacBio library prep freezer' location"

  pipeline.request_types << RequestType.create!(workflow: next_gen_sequencing, key: 'pacbio_sample_prep', name: 'PacBio Library Prep') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'Well'
    request_type.order             = 1
    request_type.multiples_allowed = false
    request_type.request_class = PacBioSamplePrepRequest
  end

  pipeline.workflow = LabInterface::Workflow.create!(name: 'PacBio Library Prep').tap do |workflow|
    [
      { class: PrepKitBarcodeTask, name: 'DNA Template Prep Kit Box Barcode',    sorted: 1, batched: true, lab_activity: true },
      { class: PlateTransferTask,  name: 'Transfer to plate',                    sorted: 2, batched: nil,  lab_activity: true, purpose: Purpose.find_by(name: 'PacBio Sheared') },
      { class: SamplePrepQcTask,   name: 'Sample Prep QC',                       sorted: 3, batched: true, lab_activity: true }
     ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'sequencing_type', 'insert_size')
end

PacBioSequencingPipeline.create!(name: 'PacBio Sequencing') do |pipeline|
  pipeline.sorter               = 14
  pipeline.automated            = false
  pipeline.active               = true
  pipeline.max_size             = 96

  pipeline.group_by_parent = false

  pipeline.location = Location.find_by(name: 'PacBio sequencing freezer') or raise StandardError, "Cannot find 'PacBio sequencing freezer' location"

  pipeline.request_types << RequestType.create!(workflow: next_gen_sequencing, key: 'pacbio_sequencing', name: 'PacBio Sequencing') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'PacBioLibraryTube'
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

  pipeline.workflow = LabInterface::Workflow.create!(name: 'PacBio Sequencing').tap do |workflow|
    [
      { class: BindingKitBarcodeTask,              name: 'Binding Kit Box Barcode', sorted: 1, batched: true, lab_activity: true },
      { class: MovieLengthTask,                    name: 'Movie Lengths',           sorted: 2, batched: true, lab_activity: true },
      { class: AssignTubesToMultiplexedWellsTask,  name: 'Layout tubes on a plate', sorted: 4, batched: true, lab_activity: true },
      { class: ValidateSampleSheetTask,            name: 'Validate Sample Sheet',   sorted: 5, batched: true, lab_activity: true }
    ].each do |details|
      details.delete(:class).create!(details.merge(workflow: workflow))
    end
  end

  Task.find_by(name: 'Movie Lengths').descriptors.create!(
      name: 'Movie length',
      kind: 'Selection',
      selection: [30, 60, 90, 120, 180, 210, 240, 270, 300, 330, 360],
      value: 180
    )
end.tap do |pipeline|
  create_request_information_types(pipeline, 'sequencing_type', 'insert_size')
end

      RequestType.create!(
        key: 'initial_pacbio_transfer',
        name: 'Initial Pacbio Transfer',
        asset_type: 'Well',
        request_class_name: 'PacBioSamplePrepRequest::Initial',
        order: 1,
        target_purpose: Purpose.find_by(name: 'PacBio Sheared')
      )

set_pipeline_flow_to('PacBio Library Prep' => 'PacBio Sequencing')

# Pulldown pipelines
['Pulldown', 'Illumina-A Pulldown'].each do |lab|
  [
    'WGS',
    'SC',
    'ISC'
  ].each do |pipeline_type|
    pipeline_name = "#{lab} #{pipeline_type}"
    Pipeline.create!(name: pipeline_name) do |pipeline|
      pipeline.sorter             = Pipeline.maximum(:sorter) + 1
      pipeline.automated          = false
      pipeline.active             = true
      pipeline.asset_type         = 'LibraryTube'
      pipeline.externally_managed = true

      pipeline.location = Location.find_by(name: 'Pulldown freezer') or raise StandardError, 'Pulldown freezer does not appear to exist!'

      pipeline.request_types << RequestType.create!(workflow: next_gen_sequencing, name: pipeline_name) do |request_type|
        request_type.billable          = true
        request_type.key               = pipeline_name.downcase.underscore.gsub(/\s+/, '_')
        request_type.initial_state     = 'pending'
        request_type.asset_type        = 'Well'
        request_type.target_purpose    = Purpose.find_by(name: 'Legacy MX tube')
        request_type.order             = 1
        request_type.multiples_allowed = false
        request_type.request_class     = "Pulldown::Requests::#{pipeline_type.humanize}LibraryRequest".constantize
        request_type.for_multiplexing  = true
      end

      pipeline.workflow = LabInterface::Workflow.create!(name: pipeline_name)
    end
  end
end

mi_seq_freezer = Location.create!(name: 'MiSeq freezer')
SequencingPipeline.create!(name: 'MiSeq sequencing') do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 2
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = mi_seq_freezer

  pipeline.request_types << RequestType.create!(workflow: next_gen_sequencing, key: 'miseq_sequencing', name: 'MiSeq sequencing') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'LibraryTube'
    request_type.order             = 1
    request_type.multiples_allowed = false
    request_type.request_class_name = MiSeqSequencingRequest.name
  end

  ['a', 'b', 'c'].each do |pl|
    pipeline.request_types << RequestType.create!(workflow: next_gen_sequencing, key: "illumina_#{pl}_miseq_sequencing", name: "Illumina-#{pl.upcase} MiSeq sequencing") do |request_type|
      request_type.initial_state     = 'pending'
      request_type.asset_type        = 'LibraryTube'
      request_type.order             = 1
      request_type.multiples_allowed = false
      request_type.request_class_name = MiSeqSequencingRequest.name
    end
  end

  pipeline.workflow = LabInterface::Workflow.create!(name: 'MiSeq sequencing') do |workflow|
    workflow.locale     = 'External'
    workflow.item_limit = 1
  end.tap do |workflow|
      t1 = SetDescriptorsTask.create!(name: 'Specify Dilution Volume', sorted: 0, workflow: workflow)
      Descriptor.create!(kind: 'Text', sorter: 1, name: 'Concentration', task: t1)
      t2 = SetDescriptorsTask.create!(name: 'Cluster Generation', sorted: 0, workflow: workflow)
      Descriptor.create!(kind: 'Text', sorter: 1, name: 'Chip barcode', task: t2)
      Descriptor.create!(kind: 'Text', sorter: 2, name: 'Cartridge barcode', task: t2)
      Descriptor.create!(kind: 'Text', sorter: 3, name: 'Operator', task: t2)
      Descriptor.create!(kind: 'Text', sorter: 4, name: 'Machine name', task: t2)
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'fragment_size_required_from', 'fragment_size_required_to', 'library_type', 'read_length')
end

    # ADD ILC Cherrypick
    cprt = RequestType.create!(
        key: 'illumina_c_cherrypick',
        name: 'Illumina-C Cherrypick',
        workflow_id: Submission::Workflow.find_by(key: 'short_read_sequencing').id,
        asset_type: 'Well',
        order: 2,
        initial_state: 'pending',
        target_asset_type: 'Well',
        request_class_name: 'Request'
        )

      liw = LabInterface::Workflow.create!(name: 'Illumina-C Cherrypick')

      LabInterface::Workflow.find_by(name: 'Cherrypick').tasks.each do |task|
        # next if task.name == 'Set Location'
        new_task = task.dup
        new_task.workflow = liw
        new_task.save!
      end

      CherrypickPipeline.create!(
        name: 'Illumina-C Cherrypick',
        active: true,
        automated: false,
        location_id: Location.find_by(name: 'Library creation freezer'),
        group_by_parent: true,
        asset_type: 'Well',
        group_name: 'Illumina-C Library creation',
        max_size: 3000,
        sorter: 10,
        request_types: [cprt],
        workflow: liw
      ) do |pipeline|
        pipeline.add_control_request_type
      end

## Fluidigm Stuff

shared_options = {
    workflow: Submission::Workflow.find_by(name: 'Microarray genotyping'),
    asset_type: 'Well',
    target_asset_type: 'Well',
    initial_state: 'pending'
}

RequestType.create!(shared_options.merge(key: 'pick_to_sta',
                                         name: 'Pick to STA',
                                         order: 1,
                                         request_class_name: 'CherrypickForPulldownRequest')
).tap do |rt|
  rt.acceptable_plate_purposes << Purpose.find_by!(name: 'Working Dilution')
end
RequestType.create!(shared_options.merge(key: 'pick_to_sta2',
                                         name: 'Pick to STA2',
                                         order: 2,
                                         request_class_name: 'CherrypickForPulldownRequest')
).tap do |rt|
  rt.acceptable_plate_purposes << Purpose.find_by!(name: 'STA')
end
RequestType.create!(shared_options.merge(key: 'pick_to_fluidigm',
                                         name: 'Pick to Fluidigm',
                                         order: 3,
                                         request_class_name: 'CherrypickForFluidigmRequest')
).tap do |rt|
  rt.acceptable_plate_purposes << Purpose.find_by!(name: 'STA2')
end
RequestType.create!(workflow: Submission::Workflow.find_by(name: 'Microarray genotyping'),
                    asset_type: 'Well',
                    target_asset_type: 'Well',
                    initial_state: 'pending',
                    key: 'pick_to_snp_type',
                    name: 'Pick to SNP Type',
                    order: 3,
                    request_class_name: 'CherrypickForPulldownRequest').tap do |rt|
  rt.acceptable_plate_purposes << Purpose.find_by!(name: 'SNP Type')
end

liw = LabInterface::Workflow.create!(name: 'Cherrypick for Fluidigm')

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
SetLocationTask.create!(
  name: 'Set Location',
  pipeline_workflow_id: liw.id,
  sorted: 3,
  batched: true,
  lab_activity: true
) do |task|
  task.location_id = Location.find_by(name: 'Sample logistics freezer').id
end

CherrypickPipeline.create!(
  name: 'Cherrypick for Fluidigm',
  active: true,
  location: Location.find_by(name: 'Sample logistics freezer'),
  group_by_parent: true,
  asset_type: 'Well',
  sorter: 11,
  paginate: false,
  summary: true,
  group_name: 'Sample Logistics',
  workflow: liw,
  request_types: RequestType.where(key: %w(pick_to_sta pick_to_sta2 pick_to_snp_type pick_to_fluidigm)),
  control_request_type_id: 0,
  max_size: 192
) do |pipeline|
end

tosta = RequestType.find_by(key: 'pick_to_sta').id
tosta2 = RequestType.find_by(key: 'pick_to_sta2').id
ptst = RequestType.find_by(key: 'pick_to_snp_type').id
tofluidigm = RequestType.find_by(key: 'pick_to_fluidigm').id

v4_requests_types_pe = ['a', 'b', 'c'].map do |pipeline|
  RequestType.create!(key: "illumina_#{pipeline}_hiseq_v4_paired_end_sequencing",
                      name: "Illumina-#{pipeline.upcase} HiSeq V4 Paired end sequencing",
                      workflow: Submission::Workflow.find_by(key: 'short_read_sequencing'),
                      asset_type: 'LibraryTube',
                      order: 2,
                      initial_state: 'pending',
                      request_class_name: 'HiSeqSequencingRequest',
                      billable: true,
                      product_line: ProductLine.find_by(name: "Illumina-#{pipeline.upcase}"))
end

v4_requests_types_se = [
  RequestType.create!(key: 'illumina_c_hiseq_v4_single_end_sequencing',
                      name: 'Illumina-C HiSeq V4 Single end sequencing',
                      workflow: Submission::Workflow.find_by(key: 'short_read_sequencing'),
                      asset_type: 'LibraryTube',
                      order: 2,
                      initial_state: 'pending',
                      request_class_name: 'HiSeqSequencingRequest',
                      billable: true,
                      product_line: ProductLine.find_by(name: 'Illumina-C'))]

x10_requests_types = ['a', 'b'].map do |pipeline|
  RequestType.create!(key: "illumina_#{pipeline}_hiseq_x_paired_end_sequencing",
                      name: "Illumina-#{pipeline.upcase} HiSeq X Paired end sequencing",
                      workflow: Submission::Workflow.find_by(key: 'short_read_sequencing'),
                      asset_type: 'LibraryTube',
                      order: 2,
                      initial_state: 'pending',
                      request_class_name: 'HiSeqSequencingRequest',
                      billable: true,
                      product_line: ProductLine.find_by(name: "Illumina-#{pipeline.upcase}"))
end << RequestType.create!(key: 'bespoke_hiseq_x_paired_end_sequencing',
                           name: 'Bespoke HiSeq X Paired end sequencing',
                           workflow: Submission::Workflow.find_by(key: 'short_read_sequencing'),
                           asset_type: 'LibraryTube',
                           order: 2,
                           initial_state: 'pending',
                           request_class_name: 'HiSeqSequencingRequest',
                           billable: true,
                           product_line: ProductLine.find_by(name: 'Illumina-C'))

st_x10 = [RequestType.create!(key: 'hiseq_x_paired_end_sequencing',
                              name: 'HiSeq X Paired end sequencing',
                              workflow: Submission::Workflow.find_by(key: 'short_read_sequencing'),
                              asset_type: 'Well',
                              order: 2,
                              initial_state: 'pending',
                              request_class_name: 'HiSeqSequencingRequest',
                              billable: true,
                              product_line: ProductLine.find_by(name: 'Illumina-B'))]

v4_pipelines = ['(spiked in controls)', '(no controls)'].each do |type|
  SequencingPipeline.create!(
    name: "HiSeq v4 PE #{type}",
    automated: false,
    active: true,
    location: Location.find_by(name: 'Cluster formation freezer'),
    group_by_parent: false,
    asset_type: 'Lane',
    sorter: 9,
    paginate: false,
    max_size: 8,
    min_size: 8,
    summary: true,
    group_name: 'Sequencing',
    control_request_type_id: 0
    ) do |pipeline|
      pipeline.workflow = LabInterface::Workflow.create!(name: pipeline.name) do |workflow|
        workflow.locale     = 'Internal'
        workflow.item_limit = 8
      end.tap do |workflow|
        [
          { class: SetDescriptorsTask,     name: 'Specify Dilution Volume',           sorted: 1, batched: true },
          { class: SetDescriptorsTask,     name: 'Cluster generation',                sorted: 3, batched: true, lab_activity: true },
          { class: AddSpikedInControlTask, name: 'Add Spiked in Control',             sorted: 4, batched: true, lab_activity: true },
          { class: SetDescriptorsTask,     name: 'Quality control',                   sorted: 5, batched: true, lab_activity: true },
          { class: SetDescriptorsTask,     name: 'Read 1 Lin/block/hyb/load',         sorted: 6, batched: true, interactive: true, per_item: true, lab_activity: true },
          { class: SetDescriptorsTask,     name: 'Read 2 Cluster/Lin/block/hyb/load', sorted: 7, batched: true, interactive: true, per_item: true, lab_activity: true }
        ].select do |task|
          type ==  '(spiked in controls)' || task[:name] != 'Add Spiked in Control'
        end.each do |details|
          details.delete(:class).create!(details.merge(workflow: workflow))
        end
      end
      pipeline.request_types = v4_requests_types_pe
    end

  SequencingPipeline.create!(
    name: "HiSeq v4 SE #{type}",
    automated: false,
    active: true,
    location: Location.find_by(name: 'Cluster formation freezer'),
    group_by_parent: false,
    asset_type: 'Lane',
    sorter: 9,
    paginate: false,
    max_size: 8,
    min_size: 8,
    summary: true,
    group_name: 'Sequencing',
    control_request_type_id: 0
    ) do |pipeline|
      pipeline.workflow = LabInterface::Workflow.create!(name: pipeline.name) do |workflow|
        workflow.locale     = 'Internal'
        workflow.item_limit = 8
      end.tap do |workflow|
        [
          { class: SetDescriptorsTask,     name: 'Specify Dilution Volume',           sorted: 1, batched: true },
          { class: SetDescriptorsTask,     name: 'Cluster generation',                sorted: 3, batched: true, lab_activity: true },
          { class: AddSpikedInControlTask, name: 'Add Spiked in Control',             sorted: 4, batched: true, lab_activity: true },
          { class: SetDescriptorsTask,     name: 'Quality control',                   sorted: 5, batched: true, lab_activity: true },
          { class: SetDescriptorsTask,     name: 'Read 1 Lin/block/hyb/load',         sorted: 6, batched: true, interactive: true, per_item: true, lab_activity: true }
        ].select do |task|
          type ==  '(spiked in controls)' || task[:name] != 'Add Spiked in Control'
        end.each do |details|
          details.delete(:class).create!(details.merge(workflow: workflow))
        end
      end
      pipeline.request_types = v4_requests_types_se
    end
end

x10_pipelines = ['(spiked in controls)', '(no controls)'].each do |type|
  SequencingPipeline.create!(
    name: "HiSeq X PE #{type}",
    automated: false,
    active: true,
    location: Location.find_by(name: 'Cluster formation freezer'),
    group_by_parent: false,
    asset_type: 'Lane',
    sorter: 9,
    paginate: false,
    max_size: 8,
    min_size: 8,
    summary: true,
    group_name: 'Sequencing',
    control_request_type_id: 0
    ) do |pipeline|
      pipeline.workflow = LabInterface::Workflow.create!(name: pipeline.name) do |workflow|
        workflow.locale     = 'Internal'
        workflow.item_limit = 8
      end.tap do |workflow|
        [
        { class: SetDescriptorsTask,     name: 'Specify Dilution Volume',           sorted: 1, batched: true },
        { class: SetDescriptorsTask,     name: 'Cluster generation',                sorted: 3, batched: true, lab_activity: true },
        { class: AddSpikedInControlTask, name: 'Add Spiked in Control',             sorted: 4, batched: true, lab_activity: true },
        { class: SetDescriptorsTask,     name: 'Read 1 Lin/block/hyb/load',         sorted: 6, batched: true, interactive: true, per_item: true, lab_activity: true },
        { class: SetDescriptorsTask,     name: 'Read 2 Cluster/Lin/block/hyb/load', sorted: 7, batched: true, interactive: true, per_item: true, lab_activity: true }
        ].select do |task|
          type == '(spiked in controls)' || task[:name] != 'Add Spiked in Control'
        end.each do |details|
          details.delete(:class).create!(details.merge(workflow: workflow))
        end
      end
      pipeline.request_types = x10_requests_types
    end
end
st_x10_pipelines = ['(spiked in controls) from strip-tubes'].each do |type|
  UnrepeatableSequencingPipeline.create!(
    name: "HiSeq X PE #{type}",
    automated: false,
    active: true,
    location: Location.find_by(name: 'Cluster formation freezer'),
    group_by_parent: true,
    asset_type: 'Lane',
    sorter: 9,
    paginate: false,
    max_size: 8,
    min_size: 8,
    summary: true,
    group_name: 'Sequencing',
    control_request_type_id: 0
    ) do |pipeline|
      pipeline.workflow = LabInterface::Workflow.create!(name: pipeline.name) do |workflow|
        workflow.locale     = 'Internal'
        workflow.item_limit = 8
      end.tap do |workflow|
        [
        { class: SetDescriptorsTask,     name: 'Specify Dilution Volume',           sorted: 1, batched: true },
        { class: SetDescriptorsTask,     name: 'Cluster generation',                sorted: 3, batched: true, lab_activity: true },
        { class: AddSpikedInControlTask, name: 'Add Spiked in Control',             sorted: 4, batched: true, lab_activity: true },
        { class: SetDescriptorsTask,     name: 'Read 1 Lin/block/hyb/load',         sorted: 6, batched: true, interactive: true, per_item: true, lab_activity: true },
        { class: SetDescriptorsTask,     name: 'Read 2 Cluster/Lin/block/hyb/load', sorted: 7, batched: true, interactive: true, per_item: true, lab_activity: true }
        ].each do |details|
          details.delete(:class).create!(details.merge(workflow: workflow))
        end
      end
      pipeline.request_types = st_x10
    end
end

['htp', 'c'].each do |pipeline|
  RequestType.create!(key: "illumina_#{pipeline}_hiseq_4000_paired_end_sequencing",
                      name: "Illumina-#{pipeline.upcase} HiSeq 4000 Paired end sequencing",
                      workflow: Submission::Workflow.find_by(key: 'short_read_sequencing'),
                      asset_type: 'LibraryTube',
                      order: 2,
                      initial_state: 'pending',
                      request_class_name: 'HiSeqSequencingRequest',
                      billable: true,
                      product_line: ProductLine.find_by(name: "Illumina-#{pipeline.upcase}"),
                      request_purpose: RequestPurpose.standard).tap do |rt|
    RequestType::Validator.create!(request_type: rt, request_option: 'read_length', valid_options: [150, 75])
  end
  RequestType.create!(key: "illumina_#{pipeline}_hiseq_4000_single_end_sequencing",
                      name: "Illumina-#{pipeline.upcase} HiSeq 4000 Single end sequencing",
                      workflow: Submission::Workflow.find_by(key: 'short_read_sequencing'),
                      asset_type: 'LibraryTube',
                      order: 2,
                      initial_state: 'pending',
                      request_class_name: 'HiSeqSequencingRequest',
                      billable: true,
                      product_line: ProductLine.find_by(name: "Illumina-#{pipeline.upcase}"),
                      request_purpose: RequestPurpose.standard).tap do |rt|
    RequestType::Validator.create!(request_type: rt, request_option: 'read_length', valid_options: [50])
  end
end

  def build_4000_tasks_for(workflow, paired_only = false)
    AddSpikedInControlTask.create!(name: 'Add Spiked in control', sorted: 0, workflow: workflow)
    SetDescriptorsTask.create!(name: 'Cluster Generation', sorted: 1, workflow: workflow) do |task|
      task.descriptors.build([
        { kind: 'Text', sorter: 1, name: 'Chip Barcode', required: true },
        { kind: 'Text', sorter: 2, name: 'Operator' },
        { kind: 'Text', sorter: 3, name: 'Pipette Carousel #' },
        { kind: 'Text', sorter: 4, name: 'CBOT' },
        { kind: 'Text', sorter: 5, name: '-20 Temp. Read 1 Cluster Kit (Box 1 of 2) Lot #' },
        { kind: 'Text', sorter: 6, name: '-20 Temp. Read 1 Cluster Kit (Box 1 of 2) RGT #' },
        { kind: 'Text', sorter: 8, name: 'Comment' }
      ])
    end

    SetDescriptorsTask.create!(name: 'Read 1 Lin/block/hyb/load', sorted: 2, workflow: workflow) do |task|
      task.descriptors.build([
        { kind: 'Text', sorter: 1, name: 'Chip Barcode', required: true },
        { kind: 'Text', sorter: 2, name: 'Operator' },
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
      ])
    end

    SetDescriptorsTask.create!(name: 'Read 2 Lin/block/hyb/load', sorted: 2, workflow: workflow) do |task|
      if paired_only
        task.descriptors.build([
          { kind: 'Text', sorter: 1, name: 'Operator' },
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
        ])
      else
        task.descriptors.build([
          { kind: 'Text', sorter: 1, name: 'Operator' },
          { kind: 'Text', sorter: 2, name: 'Pipette Carousel #' },
          { kind: 'Text', sorter: 3, name: '-20 Temp. Read 1 Cluster Kit Lot #' },
          { kind: 'Text', sorter: 4, name: '-20 Temp. Read 1 Cluster Kit RGT #' },
          { kind: 'Text', sorter: 5, name: 'Resynthesis Mix (HRM)' },
          { kind: 'Text', sorter: 6, name: 'Denaturation Mix (HDR)' },
          { kind: 'Text', sorter: 7, name: 'Index 1 Primer Mix (HP12)' },
          { kind: 'Text', sorter: 8, name: 'Comments' }
        ])
      end
    end
  end

  def add_4000_information_types_to(pipeline)
    pipeline.request_information_types << RequestInformationType.where(label: 'Vol.', hide_in_inbox: false).first!
    pipeline.request_information_types << RequestInformationType.where(label: 'Read length', hide_in_inbox: false).first!
  end

 SequencingPipeline.create!(
        name: 'HiSeq 4000 PE (spiked in controls)',
        asset_type: 'Lane',
        automated: false,
        active: true,
        location:  Location.find_by(name: 'Cluster formation freezer'),
        sorter: 10,
        max_size: 8,
        group_name: 'Sequencing',
        control_request_type_id: 0,
        min_size: 8
      ) do |pipeline|
        pipeline.request_types = RequestType.where("`key` LIKE 'illumina_%_hiseq_4000_paired_end_sequencing'")
        pipeline.build_workflow(name: 'HiSeq 4000 PE').tap do |wf|
          build_4000_tasks_for(wf, true)
        end
        add_4000_information_types_to(pipeline)
      end

      SequencingPipeline.create!(
        name: 'HiSeq 4000 SE (spiked in controls)',
        asset_type: 'Lane',
        automated: false,
        active: true,
        location:  Location.find_by(name: 'Cluster formation freezer'),
        sorter: 10,
        max_size: 8,
        group_name: 'Sequencing',
        control_request_type_id: 0,
        min_size: 8
      ) do |pipeline|
        pipeline.request_types = RequestType.where("`key` LIKE 'illumina_%_hiseq_4000_single_end_sequencing'")
        pipeline.build_workflow(name: 'HiSeq 4000 SE').tap do |wf|
          build_4000_tasks_for(wf)
        end
        add_4000_information_types_to(pipeline)
      end
