require 'control_request_type_creation'

Pipeline.send(:include, ControlRequestTypeCreation)
Pipeline.send(:before_save, :add_control_request_type)

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
#       pipeline.location = Location.first(:conditions => { :name => YYYY }) or raise StandardError, "Cannot find 'YYYY' location'
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
    current_pipeline, next_pipeline = [ current_name, next_name ].map { |name| Pipeline.first(:conditions => { :name => name }) or raise "Cannot find pipeline '#{ name }'" }
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
  'PacBio sample prep freezer',
  'PacBio sequencing freezer'
]
Location.import [ :name ], locations_data, :validate => false


#### RequestInformationTypes
request_information_types_data = [
  ["Fragment size required (from)", "fragment_size_required_from", "Fragment size required (from)", 0 ],
  ["Fragment size required (to)", "fragment_size_required_to", "Fragment size required (to)", 0 ],
  ["Read length", "read_length", "Read length", 0 ],
  ["Library type", "library_type", "Library type", 0 ],
  ["Concentration", "concentration", "Concentration", 1 ],
  ["Concentration", "concentration", "Vol.", 0 ],
  ["Sequencing Type", 'sequencing_type', 'Sequencing Type', 0 ],
  ['Insert Size', 'insert_size', 'Insert Size', 0 ]
]
RequestInformationType.import [:name, :key, :label, :hide_in_inbox], request_information_types_data, :validate => false



REQUEST_INFORMATION_TYPES = Hash[RequestInformationType.all.map { |t| [ t.key, t ] }].freeze
def create_request_information_types(pipeline, *keys)
  PipelineRequestInformationType.create!(keys.map { |k| { :pipeline => pipeline, :request_information_type => REQUEST_INFORMATION_TYPES[k] } })
end


##################################################################################################################
# Next-gen sequencing
##################################################################################################################
next_gen_sequencing = Submission::Workflow.create! do |workflow|
  workflow.key        = 'short_read_sequencing'
  workflow.name       = 'Next-gen sequencing'
  workflow.item_label = 'library'
end

LibraryCreationPipeline.create!(:name => 'Illumina-C Library preparation') do |pipeline|
  pipeline.asset_type = 'LibraryTube'
  pipeline.sorter     = 0
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.first(:conditions => { :name => 'Library creation freezer' }) or raise StandardError, "Cannot find 'Library creation freezer' location"

  pipeline.request_types << RequestType.create!(:workflow => next_gen_sequencing, :key => 'library_creation', :name => 'Library creation') do |request_type|
    request_type.billable           = true
    request_type.initial_state      = 'pending'
    request_type.asset_type         = 'SampleTube'
    request_type.order              = 1
    request_type.multiples_allowed  = false
    request_type.request_class_name = LibraryCreationRequest.name
  end

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'Library preparation') do |workflow|
    workflow.locale   = 'External'
  end.tap do |workflow|
    fragment_family = Family.create!(:name => "Fragment", :description => "Archived fragment")
    Descriptor.create!(:name => "start", :family_id => fragment_family.id)

    [
      { :class => SetDescriptorsTask, :name => 'Initial QC',       :sorted => 0 },
      { :class => SetDescriptorsTask, :name => 'Gel',              :sorted => 1, :interactive => false, :per_item => false, :families => [fragment_family] },
      { :class => SetDescriptorsTask, :name => 'Characterisation', :sorted => 2, :batched => true, :interactive => false, :per_item => false }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'fragment_size_required_from', 'fragment_size_required_to', 'library_type')
end

MultiplexedLibraryCreationPipeline.create!(:name => 'Illumina-B MX Library Preparation') do |pipeline|
  pipeline.asset_type          = 'LibraryTube'
  pipeline.sorter              = 0
  pipeline.automated           = false
  pipeline.active              = true
  pipeline.multiplexed         = true

  pipeline.location = Location.first(:conditions => { :name => 'Library creation freezer' }) or raise StandardError, "Cannot find 'Library creation freezer' location"

  pipeline.request_types << RequestType.create!(
    :workflow => next_gen_sequencing,
    :key => 'multiplexed_library_creation',
    :name => 'Multiplexed library creation'
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
    :workflow => Submission::Workflow.find_by_key('short_read_sequencing'),
    :key      => 'illumina_b_multiplexed_library_creation',
    :name     => 'Illumina-B Multiplexed Library Creation'
  ) do |request_type|
    request_type.billable          = true
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'SampleTube'
    request_type.order             = 1
    request_type.multiples_allowed = false
    request_type.request_class     = MultiplexedLibraryCreationRequest
    request_type.for_multiplexing  = true
  end

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'Illumina-B MX Library Preparation') do |workflow|
    workflow.locale   = 'External'
  end.tap do |workflow|
    [
      { :class => TagGroupsTask,      :name => 'Tag Groups',       :sorted => 0 },
      { :class => AssignTagsTask,     :name => 'Assign Tags',      :sorted => 1 },
      { :class => SetDescriptorsTask, :name => 'Initial QC',       :sorted => 2, :batched => false },
      { :class => SetDescriptorsTask, :name => 'Gel',              :sorted => 3, :batched => false },
      { :class => SetDescriptorsTask, :name => 'Characterisation', :sorted => 4, :batched => true }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, "fragment_size_required_from", "fragment_size_required_to", "read_length", "library_type")
  PipelineRequestInformationType.create!(:pipeline => pipeline, :request_information_type => RequestInformationType.find_by_label("Concentration"))
end

MultiplexedLibraryCreationPipeline.create!(:name => 'Illumina-C MX Library Preparation') do |pipeline|
  pipeline.asset_type  = 'LibraryTube'
  pipeline.sorter      = 0
  pipeline.automated   = false
  pipeline.active      = true
  pipeline.multiplexed = true
  pipeline.group_name  = "Library creation"

  pipeline.location = Location.first(
    :conditions => { :name => 'Library creation freezer' }
  ) or raise StandardError, "Cannot find 'Library creation freezer' location"

  pipeline.request_types << RequestType.create!(
    :workflow => Submission::Workflow.find_by_key('short_read_sequencing'),
    :key      => 'illumina_c_multiplexed_library_creation',
    :name     => 'Illumina-C Multiplexed Library Creation'
  ) do |request_type|
    request_type.billable          = true
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'SampleTube'
    request_type.order             = 1
    request_type.multiples_allowed = false
    request_type.request_class     = MultiplexedLibraryCreationRequest
    request_type.for_multiplexing  = true
  end


  pipeline.workflow = LabInterface::Workflow.create!(:name => 'Illumina-C MX Library Preparation workflow') do |workflow|
    workflow.locale   = 'External'
  end.tap do |workflow|
    {
      TagGroupsTask      => { :name => 'Tag Groups',       :sorted => 0 },
      AssignTagsTask     => { :name => 'Assign Tags',      :sorted => 1 },
      SetDescriptorsTask => { :name => 'Initial QC',       :sorted => 2, :batched => false },
      SetDescriptorsTask => { :name => 'Gel',              :sorted => 3, :batched => false },
      SetDescriptorsTask => { :name => 'Characterisation', :sorted => 4, :batched => true }
    }.each do |klass, details|
      klass.create!(details.merge(:workflow => workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(
    pipeline,
    "fragment_size_required_from",
    "fragment_size_required_to",
    "read_length",
    "library_type"
  )

  PipelineRequestInformationType.create!(
    :pipeline => pipeline,
    :request_information_type => RequestInformationType.find_by_label("Concentration")
  )
end

PulldownLibraryCreationPipeline.create!(:name => 'Pulldown library preparation') do |pipeline|
  pipeline.asset_type = 'LibraryTube'
  pipeline.sorter     = 12
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.first(:conditions => { :name => 'Library creation freezer' }) or raise StandardError, "Cannot find 'Library creation freezer' location"

  pipeline.request_types << RequestType.create!(:workflow => next_gen_sequencing, :key => 'pulldown_library_creation', :name => 'Pulldown library creation') do |request_type|
    request_type.billable          = true
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'SampleTube'
    request_type.order             = 1
    request_type.multiples_allowed = false
    request_type.request_class = LibraryCreationRequest
  end

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'Pulldown library preparation') do |workflow|
    workflow.locale   = 'External'
  end.tap do |workflow|
    [
      { :class => SetDescriptorsTask, :name => 'Shearing',               :sorted => 0, :batched => false, :interactive => true },
      { :class => SetDescriptorsTask, :name => 'Library preparation',    :sorted => 1, :batched => false, :interactive => true },
      { :class => SetDescriptorsTask, :name => 'Pre-hybridisation PCR',  :sorted => 2, :batched => false, :interactive => true },
      { :class => SetDescriptorsTask, :name => 'Hybridisation',          :sorted => 3, :batched => false, :interactive => true },
      { :class => SetDescriptorsTask, :name => 'Post-hybridisation PCR', :sorted => 4, :batched => false, :interactive => true },
      { :class => SetDescriptorsTask, :name => 'qPCR',                   :sorted => 5, :batched => false, :interactive => true }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end

cluster_formation_se_request_type = RequestType.create!(:workflow => next_gen_sequencing, :key => 'single_ended_sequencing', :name => 'Single ended sequencing') do |request_type|
  request_type.billable          = true
  request_type.initial_state     = 'pending'
  request_type.asset_type        = 'LibraryTube'
  request_type.order             = 2
  request_type.multiples_allowed = true
  request_type.request_class =  SequencingRequest
end

SequencingPipeline.create!(:name => 'Cluster formation SE (spiked in controls)', :request_types => [ cluster_formation_se_request_type ]) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 2
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"
  pipeline.workflow = LabInterface::Workflow.create!(:name => 'Cluster formation SE (spiked in controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      # NOTE: Yes, there's a typo in the name here:
      { :class => SetDescriptorsTask,     :name => 'Specify Dilution Volume ',  :sorted => 1, :batched => true },
      { :class => AddSpikedInControlTask, :name => 'Add Spiked in Control',     :sorted => 2, :batched => true },
      { :class => SetDescriptorsTask,     :name => 'Cluster generation',        :sorted => 3, :batched => true, :interactive => false, :per_item => false },
      { :class => SetDescriptorsTask,     :name => 'Quality control',           :sorted => 4, :batched => true, :interactive => false, :per_item => false },
      { :class => SetDescriptorsTask,     :name => 'Lin/block/hyb/load',        :sorted => 5, :batched => true, :interactive => false, :per_item => false }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end.tap do |pipeline|
  PipelineRequestInformationType.create!(:pipeline => pipeline, :request_information_type => RequestInformationType.find_by_key("read_length"))
  PipelineRequestInformationType.create!(:pipeline => pipeline, :request_information_type => RequestInformationType.find_by_key("library_type"))
  PipelineRequestInformationType.create!(:pipeline => pipeline, :request_information_type => RequestInformationType.find_by_label("Vol."))
end

SequencingPipeline.create!(:name => 'Cluster formation SE', :request_types => [ cluster_formation_se_request_type ]) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 2
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'Cluster formation SE') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      # NOTE: Yes, there's a typo in the name here:
      { :class => SetDescriptorsTask, :name => 'Specify Dilution Volume ', :sorted => 1, :batched => true },
      { :class => SetDescriptorsTask, :name => 'Cluster generation',       :sorted => 2, :batched => true, :interactive => false, :per_item => false },
      { :class => SetDescriptorsTask, :name => 'Quality control',          :sorted => 3, :batched => true, :interactive => false, :per_item => false },
      { :class => SetDescriptorsTask, :name => 'Lin/block/hyb/load',       :sorted => 4, :batched => true, :interactive => false, :per_item => false }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, "read_length", "library_type")
  PipelineRequestInformationType.create!(:pipeline => pipeline, :request_information_type => RequestInformationType.find_by_label("Vol."))
end

SequencingPipeline.create!(:name => 'Cluster formation SE (no controls)', :request_types => [ cluster_formation_se_request_type ]) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 2
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'Cluster formation SE (no controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      # NOTE: Yes, there's a typo in the name here:
      { :class => SetDescriptorsTask, :name => 'Specify Dilution Volume ', :sorted => 1, :batched => true },
      { :class => SetDescriptorsTask, :name => 'Cluster generation',       :sorted => 2, :batched => true, :interactive => false, :per_item => false },
      { :class => SetDescriptorsTask, :name => 'Quality control',          :sorted => 3, :batched => true, :interactive => false, :per_item => false },
      { :class => SetDescriptorsTask, :name => 'Lin/block/hyb/load',       :sorted => 4, :batched => true, :interactive => false, :per_item => false }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, "read_length", "library_type")
  PipelineRequestInformationType.create!(:pipeline => pipeline, :request_information_type => RequestInformationType.find_by_label("Vol."))
end

single_ended_hi_seq_sequencing = RequestType.create!(:workflow => next_gen_sequencing, :key => 'single_ended_hi_seq_sequencing', :name => 'Single ended hi seq sequencing') do |request_type|
  request_type.billable          = true
  request_type.initial_state     = 'pending'
  request_type.asset_type        = 'LibraryTube'
  request_type.order             = 2
  request_type.multiples_allowed = true
  request_type.request_class =  HiSeqSequencingRequest
end

SequencingPipeline.create!(:name => 'Cluster formation SE HiSeq', :request_types => [ single_ended_hi_seq_sequencing ]) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 2
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'Cluster formation SE HiSeq') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      # NOTE: Yes, there's a typo in the name here:
      { :class => SetDescriptorsTask, :name => 'Specify Dilution Volume ', :sorted => 1, :batched => true },
      { :class => SetDescriptorsTask, :name => 'Cluster generation',       :sorted => 2, :batched => true, :interactive => false, :per_item => false },
      { :class => SetDescriptorsTask, :name => 'Quality control',          :sorted => 3, :batched => true, :interactive => false, :per_item => false },
      { :class => SetDescriptorsTask, :name => 'Lin/block/hyb/load',       :sorted => 4, :batched => true, :interactive => false, :per_item => false }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, "read_length", "library_type")
  PipelineRequestInformationType.create!(:pipeline => pipeline, :request_information_type => RequestInformationType.find_by_label("Vol."))
end

SequencingPipeline.create!(:name => 'Cluster formation SE HiSeq (no controls)', :request_types => [ single_ended_hi_seq_sequencing ]) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 2
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'Cluster formation SE HiSeq (no controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      # NOTE: Yes, there's a typo in the name here:
      { :class => SetDescriptorsTask, :name => 'Specify Dilution Volume ', :sorted => 1, :batched => true },
      { :class => SetDescriptorsTask, :name => 'Cluster generation',       :sorted => 2, :batched => true, :interactive => false, :per_item => false },
      { :class => SetDescriptorsTask, :name => 'Quality control',          :sorted => 3, :batched => true, :interactive => false, :per_item => false },
      { :class => SetDescriptorsTask, :name => 'Lin/block/hyb/load',       :sorted => 4, :batched => true, :interactive => false, :per_item => false }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, "read_length", "library_type")
  PipelineRequestInformationType.create!(:pipeline => pipeline, :request_information_type => RequestInformationType.find_by_label("Vol."))
end

cluster_formation_pe_request_type = RequestType.create!(:workflow => next_gen_sequencing, :key => 'paired_end_sequencing', :name => 'Paired end sequencing') do |request_type|
  request_type.billable          = true
  request_type.initial_state     = 'pending'
  request_type.asset_type        = 'LibraryTube'
  request_type.order             = 2
  request_type.multiples_allowed = true
  request_type.request_class =  SequencingRequest
end

SequencingPipeline.create!(:name => 'Cluster formation PE', :request_types => [ cluster_formation_pe_request_type ]) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 3
  pipeline.automated  = false
  pipeline.active     = true
  pipeline.location   = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'Cluster formation PE') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      { :class => SetDescriptorsTask, :name => 'Specify Dilution Volume',           :sorted => 1, :batched => true },
      { :class => SetDescriptorsTask, :name => 'Cluster generation',                :sorted => 2, :batched => true, :interactive => false, :per_item => false },
      { :class => SetDescriptorsTask, :name => 'Quality control',                   :sorted => 3, :batched => true, :interactive => false, :per_item => false },
      { :class => SetDescriptorsTask, :name => 'Read 1 Lin/block/hyb/load',         :sorted => 4, :batched => true, :interactive => true, :per_item => true },
      { :class => SetDescriptorsTask, :name => 'Read 2 Cluster/Lin/block/hyb/load', :sorted => 5, :batched => true, :interactive => true, :per_item => true }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, "read_length", "library_type")
  PipelineRequestInformationType.create!(:pipeline => pipeline, :request_information_type => RequestInformationType.find_by_label("Vol."))
end

SequencingPipeline.create!(:name => 'Cluster formation PE (no controls)', :request_types => [ cluster_formation_pe_request_type ]) do |pipeline|
  pipeline.asset_type      = 'Lane'
  pipeline.sorter          = 8
  pipeline.automated       = false
  pipeline.active          = true
  pipeline.group_by_parent = false
  pipeline.location        = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'Cluster formation PE (no controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      { :class => SetDescriptorsTask, :name => 'Specify Dilution Volume',           :sorted => 1, :batched => true },
      { :class => SetDescriptorsTask, :name => 'Cluster generation',                :sorted => 2, :batched => true },
      { :class => SetDescriptorsTask, :name => 'Quality control',                   :sorted => 3, :batched => true },
      { :class => SetDescriptorsTask, :name => 'Read 1 Lin/block/hyb/load',         :sorted => 4, :batched => true, :interactive => true, :per_item => true },
      { :class => SetDescriptorsTask, :name => 'Read 2 Cluster/Lin/block/hyb/load', :sorted => 5, :batched => true, :interactive => true, :per_item => true }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, "read_length", "library_type")
end

SequencingPipeline.create!(:name => 'Cluster formation PE (spiked in controls)', :request_types => [ cluster_formation_pe_request_type ]) do |pipeline|
  pipeline.asset_type      = 'Lane'
  pipeline.sorter          = 8
  pipeline.automated       = false
  pipeline.active          = true
  pipeline.group_by_parent = false
  pipeline.location        = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'Cluster formation PE (spiked in controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      { :class => SetDescriptorsTask,     :name => 'Specify Dilution Volume',           :sorted => 1, :batched => true },
      { :class => SetDescriptorsTask,     :name => 'Cluster generation',                :sorted => 2, :batched => true },
      { :class => AddSpikedInControlTask, :name => 'Add Spiked in Control',             :sorted => 3, :batched => true },
      { :class => SetDescriptorsTask,     :name => 'Quality control',                   :sorted => 4, :batched => true },
      { :class => SetDescriptorsTask,     :name => 'Read 1 Lin/block/hyb/load',         :sorted => 5, :batched => true, :interactive => true, :per_item => true },
      { :class => SetDescriptorsTask,     :name => 'Read 2 Cluster/Lin/block/hyb/load', :sorted => 6, :batched => true, :interactive => true, :per_item => true }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, "read_length", "library_type")
  PipelineRequestInformationType.create!(:pipeline => pipeline, :request_information_type => RequestInformationType.find_by_label("Vol."))
end

SequencingPipeline.create!(:name => 'HiSeq Cluster formation PE (spiked in controls)', :request_types => [ cluster_formation_pe_request_type ]) do |pipeline|
  pipeline.asset_type      = 'Lane'
  pipeline.sorter          = 9
  pipeline.automated       = false
  pipeline.active          = true
  pipeline.group_by_parent = false
  pipeline.location        = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'HiSeq Cluster formation PE (spiked in controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      { :class => SetDescriptorsTask,     :name => 'Specify Dilution Volume',           :sorted => 1, :batched => true },
      { :class => SetDescriptorsTask,     :name => 'Cluster generation',                :sorted => 2, :batched => true },
      { :class => AddSpikedInControlTask, :name => 'Add Spiked in Control',             :sorted => 3, :batched => true },
      { :class => SetDescriptorsTask,     :name => 'Quality control',                   :sorted => 4, :batched => true },
      { :class => SetDescriptorsTask,     :name => 'Read 1 Lin/block/hyb/load',         :sorted => 5, :batched => true, :interactive => true, :per_item => true },
      { :class => SetDescriptorsTask,     :name => 'Read 2 Cluster/Lin/block/hyb/load', :sorted => 6, :batched => true, :interactive => true, :per_item => true }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, "read_length", "library_type")
  PipelineRequestInformationType.create!(:pipeline => pipeline, :request_information_type => RequestInformationType.find_by_label("Vol."))
end

SequencingPipeline.create!(:name => 'Cluster formation SE HiSeq (spiked in controls)', :request_types => [ cluster_formation_pe_request_type ]) do |pipeline|
  pipeline.asset_type      = 'Lane'
  pipeline.sorter          = 8
  pipeline.automated       = false
  pipeline.active          = true
  pipeline.group_by_parent = false
  pipeline.location        = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'Cluster formation SE HiSeq (spiked in controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      { :class => SetDescriptorsTask,     :name => 'Specify Dilution Volume',           :sorted => 1, :batched => true },
      { :class => SetDescriptorsTask,     :name => 'Cluster generation',                :sorted => 2, :batched => true },
      { :class => AddSpikedInControlTask, :name => 'Add Spiked in Control',             :sorted => 3, :batched => true },
      { :class => SetDescriptorsTask,     :name => 'Quality control',                   :sorted => 4, :batched => true },
      { :class => SetDescriptorsTask,     :name => 'Read 1 Lin/block/hyb/load',         :sorted => 5, :batched => true, :interactive => true, :per_item => true },
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, "read_length", "library_type")
  PipelineRequestInformationType.create!(:pipeline => pipeline, :request_information_type => RequestInformationType.find_by_label("Vol."))
end

# TODO: This pipeline has been cloned from the 'Cluster formation PE (no controls)'.  Needs checking
SequencingPipeline.create!(:name => 'HiSeq Cluster formation PE (no controls)') do |pipeline|
  pipeline.asset_type      = 'Lane'
  pipeline.sorter          = 8
  pipeline.automated       = false
  pipeline.active          = true
  pipeline.group_by_parent = false
  pipeline.location        = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.request_types << RequestType.create!(:workflow => next_gen_sequencing, :key => 'hiseq_paired_end_sequencing', :name => 'HiSeq Paired end sequencing') do |request_type|
    request_type.billable          = true
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'LibraryTube'
    request_type.order             = 2
    request_type.multiples_allowed = true
    request_type.request_class =  HiSeqSequencingRequest
  end

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'HiSeq Cluster formation PE (no controls)') do |workflow|
    workflow.locale     = 'Internal'
    workflow.item_limit = 8
  end.tap do |workflow|
    [
      { :class => SetDescriptorsTask, :name => 'Specify Dilution Volume',           :sorted => 1, :batched => true },
      { :class => SetDescriptorsTask, :name => 'Cluster generation',                :sorted => 2, :batched => true },
      { :class => SetDescriptorsTask, :name => 'Quality control',                   :sorted => 3, :batched => true },
      { :class => SetDescriptorsTask, :name => 'Read 1 Lin/block/hyb/load',         :sorted => 4, :batched => true, :interactive => true, :per_item => true },
      { :class => SetDescriptorsTask, :name => 'Read 2 Cluster/Lin/block/hyb/load', :sorted => 5, :batched => true, :interactive => true, :per_item => true }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, "read_length", "library_type")
  PipelineRequestInformationType.create!(:pipeline => pipeline, :request_information_type => RequestInformationType.find_by_label("Vol."))
end

##################################################################################################################
# Microarray genotyping
##################################################################################################################
microarray_genotyping = Submission::Workflow.create! do |workflow|
  workflow.key        = 'microarray_genotyping'
  workflow.name       = 'Microarray genotyping'
  workflow.item_label = 'Run'
end

CherrypickPipeline.create!(:name => 'Cherrypick') do |pipeline|
  pipeline.asset_type          = 'Well'
  pipeline.sorter              = 10
  pipeline.automated           = false
  pipeline.active              = true
  pipeline.group_by_parent     = true

  pipeline.location = Location.first(:conditions => { :name => 'Sample logistics freezer' }) or raise StandardError, "Cannot find 'Sample logistics freezer' location"

  pipeline.request_types << RequestType.create!(:workflow => microarray_genotyping, :key => 'cherrypick', :name => 'Cherrypick') do |request_type|
    request_type.initial_state     = 'blocked'
    request_type.target_asset_type = 'Well'
    request_type.asset_type        = 'Well'
    request_type.order             = 2
    request_type.request_class     = Request
    request_type.multiples_allowed = false
  end

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'Cherrypick').tap do |workflow|
    # NOTE[xxx]: Note that the order here, and 'Set Location' being interactive, do not mimic the behaviour of production
    [
      { :class => PlateTemplateTask,      :name => "Select Plate Template",              :sorted => 1, :batched => true },
      { :class => CherrypickTask,         :name => "Approve Plate Layout",               :sorted => 2, :batched => true },
      { :class => SetLocationTask,        :name => "Set Location",                       :sorted => 4 }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end

CherrypickForPulldownPipeline.create!(:name => 'Cherrypicking for Pulldown') do |pipeline|
  pipeline.asset_type          = 'Well'
  pipeline.sorter              = 13
  pipeline.automated           = false
  pipeline.active              = true
  pipeline.group_by_parent     = true

  pipeline.location = Location.first(:conditions => { :name => 'Sample logistics freezer' }) or raise StandardError, "Cannot find 'Sample logistics freezer' location"

  cherrypicking_attributes = lambda do |request_type|
    request_type.initial_state     = 'pending'
    request_type.target_asset_type = 'Well'
    request_type.asset_type        = 'Well'
    request_type.order             = 1
    request_type.request_class     = CherrypickForPulldownRequest
    request_type.multiples_allowed = false
    request_type.for_multiplexing  = false
  end

  pipeline.request_types << RequestType.create!(:workflow => next_gen_sequencing, :key => 'cherrypick_for_pulldown', :name => 'Cherrypicking for Pulldown',  &cherrypicking_attributes)

  pipeline.request_types << RequestType.create!(:workflow => next_gen_sequencing, :key => 'cherrypick_for_illumina',   :name => 'Cherrypick for Illumina',   &cherrypicking_attributes)
  pipeline.request_types << RequestType.create!(:workflow => next_gen_sequencing, :key => 'cherrypick_for_illumina_b', :name => 'Cherrypick for Illumina-B', &cherrypicking_attributes)


  pipeline.workflow = LabInterface::Workflow.create!(:name => 'Cherrypicking for Pulldown').tap do |workflow|
    # NOTE[xxx]: Note that the order here, and 'Set Location' being interactive, do not mimic the behaviour of production
    [
      { :class => CherrypickGroupBySubmissionTask, :name => 'Cherrypick Group By Submission', :sorted => 0, :batched => true },
      { :class => SetLocationTask,                 :name => 'Set location', :sorted => 1 }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end

DnaQcPipeline.create!(:name => 'DNA QC') do |pipeline|
  pipeline.sorter              = 9
  pipeline.automated           = false
  pipeline.active              = true
  pipeline.group_by_parent     = true

  pipeline.location = Location.first(:conditions => { :name => 'Sample logistics freezer' }) or raise StandardError, "Cannot find 'Sample logistics freezer' location"

  pipeline.request_types << RequestType.create!(:workflow => microarray_genotyping, :key => 'dna_qc', :name => 'DNA QC', :no_target_asset => true) do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'Well'
    request_type.order             = 1
    request_type.request_class     = QcRequest
    request_type.multiples_allowed = false
  end

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'DNA QC').tap do |workflow|
    [
      { :class => DnaQcTask,                 :name => 'QC result',               :sorted => 1, :batched => false, :interactive => false }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end

GenotypingPipeline.create!(:name => 'Genotyping') do |pipeline|
  pipeline.sorter = 11
  pipeline.automated = false
  pipeline.active = true
  pipeline.group_by_parent = true

  pipeline.location = Location.first(:conditions => { :name => 'Genotyping freezer' }) or raise StandardError, "Cannot find 'Genotyping freezer' location"

  pipeline.request_types << RequestType.create!(:workflow => microarray_genotyping, :key => 'genotyping', :name => 'Genotyping') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'Well'
    request_type.order             = 3
    request_type.request_class     = GenotypingRequest
    request_type.multiples_allowed = false
  end

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'Genotyping').tap do |workflow|
    [
      { :class => AttachInfiniumBarcodeTask, :name => 'Attach Infinium Barcode', :sorted => 0, :batched => true },
      { :class => GenerateManifestsTask,     :name => 'Generate Manifests',      :sorted => 1, :batched => true }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end

PulldownMultiplexLibraryPreparationPipeline.create!(:name => 'Pulldown Multiplex Library Preparation') do |pipeline|
  pipeline.asset_type           = 'Well'
  pipeline.sorter               = 14
  pipeline.automated            = false
  pipeline.active               = true
  pipeline.group_by_parent      = true
  pipeline.max_size             = 96
  pipeline.max_number_of_groups = 1

  pipeline.location = Location.first(:conditions => { :name => 'Pulldown freezer' }) or raise StandardError, "Cannot find 'Pulldown freezer' location"

  pipeline.request_types << RequestType.create!(:workflow => next_gen_sequencing, :key => 'pulldown_multiplexing', :name => 'Pulldown Multiplex Library Preparation') do |request_type|
    request_type.billable          = true
    request_type.asset_type        = 'Well'
    request_type.target_asset_type = 'PulldownMultiplexedLibraryTube'
    request_type.order             = 1
    request_type.request_class     = PulldownMultiplexedLibraryCreationRequest
    request_type.multiples_allowed = false
    request_type.for_multiplexing  = true
  end

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'Pulldown Multiplex Library Preparation').tap do |workflow|
    [
      { :class => TagGroupsTask,      :name => 'Tag Groups',       :sorted => 0 },
      { :class => AssignTagsToWellsTask,     :name => 'Assign Tags to Wells',      :sorted => 1 }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end

set_pipeline_flow_to('Cherrypicking for Pulldown' => 'Pulldown Multiplex Library Preparation')
set_pipeline_flow_to('DNA QC' => 'Cherrypick')

PacBioSamplePrepPipeline.create!(:name => 'PacBio Sample Prep') do |pipeline|
  pipeline.sorter               = 14
  pipeline.automated            = false
  pipeline.active               = true
  pipeline.asset_type           = 'PacBioLibraryTube'

  pipeline.location = Location.first(:conditions => { :name => 'PacBio sample prep freezer' }) or raise StandardError, "Cannot find 'PacBio sample prep freezer' location"

  pipeline.request_types << RequestType.create!(:workflow => next_gen_sequencing, :key => 'pacbio_sample_prep', :name => 'PacBio Sample Prep') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'SampleTube'
    request_type.order             = 1
    request_type.multiples_allowed = false
    request_type.request_class = PacBioSamplePrepRequest
  end

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'PacBio Sample Prep').tap do |workflow|
    [
      { :class => PrepKitBarcodeTask, :name => 'DNA Template Prep Kit Box Barcode',    :sorted => 0, :batched => true },
      { :class => SamplePrepQcTask,   :name => 'Sample Prep QC',                       :sorted => 1, :batched => true },
      { :class => SmrtCellsTask,      :name => 'Number of SMRTcells that can be made', :sorted => 2, :batched => true }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, "sequencing_type", "insert_size")
end

PacBioSequencingPipeline.create!(:name => 'PacBio Sequencing') do |pipeline|
  pipeline.sorter               = 14
  pipeline.automated            = false
  pipeline.active               = true
  pipeline.max_size             = 96
  pipeline.asset_type           = 'Well'
  pipeline.group_by_parent = false

  pipeline.location = Location.first(:conditions => { :name => 'PacBio sequencing freezer' }) or raise StandardError, "Cannot find 'PacBio sequencing freezer' location"

  pipeline.request_types << RequestType.create!(:workflow => next_gen_sequencing, :key => 'pacbio_sequencing', :name => 'PacBio Sequencing') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'PacBioLibraryTube'
    request_type.order             = 1
    request_type.multiples_allowed = true
    request_type.request_class     = PacBioSequencingRequest
  end

  pipeline.workflow = LabInterface::Workflow.create!(:name => 'PacBio Sequencing').tap do |workflow|
    [
      { :class => BindingKitBarcodeTask,      :name => 'Binding Kit Box Barcode', :sorted => 0, :batched => true },
      { :class => MovieLengthTask,            :name => 'Movie Lengths',           :sorted => 1, :batched => true },
      { :class => ReferenceSequenceTask,      :name => 'Reference Sequence',      :sorted => 2, :batched => true },
      { :class => AssignTubesToWellsTask,     :name => 'Layout tubes on a plate', :sorted => 3, :batched => true },
      { :class => ValidateSampleSheetTask,    :name => 'Validate Sample Sheet',   :sorted => 4, :batched => true }
    ].each do |details|
      details.delete(:class).create!(details.merge(:workflow => workflow))
    end
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, "sequencing_type", "insert_size")
end

set_pipeline_flow_to('PacBio Sample Prep' => 'PacBio Sequencing')

# Pulldown pipelines
[
  'WGS',
  'SC',
  'ISC'
].each do |pipeline_type|
  pipeline_name = "Pulldown #{pipeline_type}"
  Pipeline.create!(:name => pipeline_name) do |pipeline|
    pipeline.sorter             = Pipeline.maximum(:sorter) + 1
    pipeline.automated          = false
    pipeline.active             = true
    pipeline.asset_type         = 'LibraryTube'
    pipeline.externally_managed = true

    pipeline.location   = Location.find_by_name('Pulldown freezer') or raise StandardError, "Pulldown freezer does not appear to exist!"

    pipeline.request_types << RequestType.create!(:workflow => next_gen_sequencing, :name => pipeline_name) do |request_type|
      request_type.billable          = true
      request_type.key               = pipeline_name.downcase.gsub(/\s+/, '_')
      request_type.initial_state     = 'pending'
      request_type.asset_type        = 'Well'
      request_type.target_purpose    = Tube::Purpose.standard_mx_tube
      request_type.order             = 1
      request_type.multiples_allowed = false
      request_type.request_class     = "Pulldown::Requests::#{pipeline_type.humanize}LibraryRequest".constantize
      request_type.for_multiplexing  = true
    end

    pipeline.workflow = LabInterface::Workflow.create!(:name => pipeline_name)
  end
end
