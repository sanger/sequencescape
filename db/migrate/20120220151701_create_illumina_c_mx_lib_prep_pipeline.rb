require 'control_request_type_creation'

Pipeline.send(:include, ControlRequestTypeCreation)

class CreateIlluminaCMxLibPrepPipeline < ActiveRecord::Migration

  REQUEST_INFORMATION_TYPES = Hash[RequestInformationType.all.map { |t| [ t.key, t ] }].freeze

  def self.create_request_information_types(pipeline, *keys)
    PipelineRequestInformationType.create!(
      keys.map do |k|
      {
        :pipeline                 => pipeline,
        :request_information_type => REQUEST_INFORMATION_TYPES[k]
      }
      end
    )
  end

  def self.up
    ActiveRecord::Base.transaction do
      product_line = ProductLine.find_by_name('Illumina-C')

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
          request_type.product_line      = product_line
        end

        pipeline.add_control_request_type

        pipeline.workflow = LabInterface::Workflow.create!(:name => 'Illumina-C MX Library Preparation') do |workflow|
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
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      pipeline = MultiplexedLibraryCreationPipeline.find_by_name('Illumina-C MX Library Preparation')
      # pipeline.request_types.each(&:destroy)

      LabInterface::Workflow.find_by_name('Illumina-C MX Library Preparation').destroy

      PipelineRequestInformationType.find_all_by_pipeline_id(pipeline.id).each(&:destroy)
      RequestType.find_all_by_key('illumina_c_multiplexed_library_creation').each(&:destroy)

      pipeline.destroy
    end

  end
end
