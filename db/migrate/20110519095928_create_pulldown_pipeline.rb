class CreatePulldownPipeline < ActiveRecord::Migration
  PIPELINES = [
    'Pulldown WGS',
    'Pulldown SC',
    'Pulldown ISC'
  ]

  def self.up
    ActiveRecord::Base.transaction do
      next_gen_sequencing = Submission::Workflow.find_by_key('short_read_sequencing') or raise StandardError, 'Cannot find Next-gen sequencing workflow'

      PIPELINES.each do |pipeline_name|
        Pipeline.create!(:name => pipeline_name) do |pipeline|
          pipeline.sorter          = Pipeline.maximum(:sorter) + 1
          pipeline.automated       = false
          pipeline.active          = true
          pipeline.asset_type      = 'LibraryTube'
          pipeline.group_by_parent = true

          pipeline.location = Location.create!(:name => "#{pipeline_name} freezer")

          pipeline.request_type = RequestType.create!(:workflow => next_gen_sequencing, :name => pipeline_name) do |request_type|
            request_type.key               = pipeline_name.downcase.gsub(/\s+/, '_')
            request_type.initial_state     = 'pending'
            request_type.asset_type        = 'Well'
            request_type.target_asset_type = 'MultiplexedLibraryTube'
            request_type.order             = 1
            request_type.multiples_allowed = false
            request_type.request_class     = PulldownLibraryCreationRequest
          end

          pipeline.workflow = LabInterface::Workflow.create!(:name => pipeline_name)
        end
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PIPELINES.each do |pipeline_name|
        [ Pipeline, LabInterface::Workflow, RequestType ].each { |model| model.find_by_name(pipeline_name).try(:destroy) }
        Location.find_by_name("#{pipeline_name} freezer").try(:destroy)
      end
    end
  end
end
