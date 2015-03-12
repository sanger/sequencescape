class AddMultiplexedPacbioPipelines < ActiveRecord::Migration

  require 'control_request_type_creation'
  Pipeline.send(:include, ControlRequestTypeCreation)

  REQUEST_INFORMATION_TYPES = Hash[RequestInformationType.all.map { |t| [ t.key, t ] }].freeze
  def self.create_request_information_types(pipeline, *keys)
    PipelineRequestInformationType.create!(keys.map { |k| { :pipeline => pipeline, :request_information_type => REQUEST_INFORMATION_TYPES[k] } })
  end


  def self.up
    ActiveRecord::Base.transaction do
      PacBioSequencingPipeline.find_by_name('PacBio Sequencing').request_types << RequestType.find_by_key("pacbio_multiplexed_sequencing")
      next_gen_sequencing = Submission::Workflow.find_by_key!('short_read_sequencing')

      PacBioSamplePrepPipeline.create!(:name => 'PacBio Tagged Library Prep') do |pipeline|
        pipeline.sorter               = 14
        pipeline.automated            = false
        pipeline.active               = true
        pipeline.asset_type           = 'PacBioLibraryTube'
        pipeline.group_by_parent      = true

        pipeline.location = Location.first(:conditions => { :name => 'PacBio library prep freezer' }) or raise StandardError, "Cannot find 'PacBio library prep freezer' location"

        pipeline.request_types << RequestType.find_by_key('pacbio_tagged_library_prep')

        pipeline.workflow = LabInterface::Workflow.create!(:name => 'PacBio Tagged Library Prep').tap do |workflow|
          [

            { :class => PrepKitBarcodeTask,    :name => 'DNA Template Prep Kit Box Barcode', :sorted => 1, :batched => true, :lab_activity => true },
            { :class => PlateTransferTask,     :name => 'Transfer to plate',                 :sorted => 2, :batched => nil,  :lab_activity => true, :purpose => Purpose.find_by_name('PacBio Sheared') },
            { :class => TagGroupsTask,         :name => "Tag Groups",                        :sorted => 3, :lab_activity => true },
            { :class => AssignTagsToTubesTask, :name => "Assign Tags",                       :sorted => 4, :lab_activity => true },
            { :class => SamplePrepQcTask,      :name => 'Sample Prep QC',                    :sorted => 5, :batched => true, :lab_activity => true }
           ].each do |details|
            details.delete(:class).create!(details.merge(:workflow => workflow))
          end
        end

        pipeline.add_control_request_type
      end.tap do |pipeline|
        create_request_information_types(pipeline, "sequencing_type", "insert_size")
      end

    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PacBioSequencingPipeline.find_by_name('PacBio Sequencing').request_types.reject! {|rt| rt.key == "pacbio_multiplexed_sequencing" }
      PacBioSamplePrepPipeline.find_by_name('PacBio Tagged Library Prep').destroy
    end
  end
end
