class CreatePulldownPipeline < ActiveRecord::Migration
  PIPELINE_TYPES = [
    'WGS',
    'SC',
    'ISC'
  ]

  def self.up
    ActiveRecord::Base.transaction do
      next_gen_sequencing = Submission::Workflow.find_by_key('short_read_sequencing') or raise StandardError, 'Cannot find Next-gen sequencing workflow'

      PIPELINE_TYPES.each do |pipeline_type|
        pipeline_name = "Pulldown #{pipeline_type}"
        Pipeline.create!(:name => pipeline_name) do |pipeline|
          pipeline.sorter     = Pipeline.maximum(:sorter) + 1
          pipeline.automated  = false
          pipeline.active     = true
          pipeline.asset_type = 'LibraryTube'

          pipeline.location   = Location.find_by_name('Pulldown freezer') or raise StandardError, "Pulldown freezer does not appear to exist!"

          pipeline.request_type = RequestType.create!(:workflow => next_gen_sequencing, :name => pipeline_name) do |request_type|
            request_type.key               = pipeline_name.downcase.gsub(/\s+/, '_')
            request_type.initial_state     = 'pending'
            request_type.asset_type        = 'Well'
            request_type.target_asset_type = 'MultiplexedLibraryTube'
            request_type.order             = 1
            request_type.multiples_allowed = false
            request_type.request_class     = "Pulldown::Requests::#{pipeline_type.humanize}LibraryRequest".constantize
            request_type.for_multiplexing  = true
          end

          pipeline.workflow = LabInterface::Workflow.create!(:name => pipeline_name)
        end
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PIPELINE_TYPES.each do |pipeline_type|
        pipeline_name = "Pulldown #{pipeline_name}"
        [ Pipeline, LabInterface::Workflow, RequestType ].each { |model| model.find_by_name(pipeline_name).try(:destroy) }
        Location.find_by_name("#{pipeline_name} freezer").try(:destroy)
      end
    end
  end
end
