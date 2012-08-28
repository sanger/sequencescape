require 'control_request_type_creation'

class CreateIlluminaBMxLibPrepRequestTypes < ActiveRecord::Migration
  REQUEST_INFORMATION_TYPES = Hash[RequestInformationType.all.map { |t| [ t.key, t ] }].freeze

  def self.create_request_information_types(pipeline, *keys)
    Pipeline.send(:include, ControlRequestTypeCreation)

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
      product_line = ProductLine.find_by_name('Illumina-B')
      pipeline = MultiplexedLibraryCreationPipeline.find_by_name('Illumina-B MX Library Preparation')

      pipeline.request_types << RequestType.create!(
        :workflow => Submission::Workflow.find_by_key('short_read_sequencing'),
        :key      => 'illumina_b_multiplexed_library_creation',
        :name     => 'Illumina-B Multiplexed Library Creation',
        :billable          => true,
        :initial_state     => 'pending',
        :asset_type        => 'SampleTube',
        :order             => 1,
        :multiples_allowed => false,
        :request_class     => MultiplexedLibraryCreationRequest,
        :for_multiplexing  => true,
        :product_line      => product_line
      )
      
      pipeline.add_control_request_type
      
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_key('illumina_b_multiplexed_library_creation').each(&:destroy)
    end

  end
end
