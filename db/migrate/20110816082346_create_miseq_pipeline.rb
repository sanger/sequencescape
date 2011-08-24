class CreateMiseqPipeline < ActiveRecord::Migration
     REQUEST_INFORMATION_TYPES = Hash[RequestInformationType.all.map { |t| [ t.key, t ] }].freeze
     def self.create_request_information_types(pipeline, *keys)
       PipelineRequestInformationType.create!(keys.map { |k| { :pipeline => pipeline, :request_information_type => REQUEST_INFORMATION_TYPES[k] } })
     end


  def self.up

     # postfix to run the migraiton multiple times
     counter = ""
  
     ## Helper
     ## Create MiSeq freezer
     mi_seq_freezer = Location.create!({:name => "MiSeq freezer"})
     
     ## Submission workflow
     next_gen_sequencing = Submission::Workflow.find_by_key('short_read_sequencing') or raise "Unable to find submission workflow"
 
     say "Library pipelines" 
     ## Lab pipelines
     SequencingPipeline.create!(:name => "MiSeq sequencing#{counter}") do |pipeline|
					pipeline.asset_type = 'Lane'
					pipeline.sorter     = 2 
					pipeline.automated  = false
					pipeline.active     = true

					pipeline.location = mi_seq_freezer

					pipeline.request_type = RequestType.create!(:workflow => next_gen_sequencing, :key => 'miseq_sequencing', :name => "MiSeq sequencing#{counter}") do |request_type|
						request_type.initial_state     = 'pending'
						request_type.asset_type        = 'LibraryTube'
						request_type.order             = 1
						request_type.multiples_allowed = false
						request_type.request_class_name = SequencingRequest.name
					end

					pipeline.workflow = LabInterface::Workflow.create!(:name => "MiSeq sequencing#{counter}") do |workflow|
						workflow.locale     = 'External'
						workflow.item_limit = 1
					end.tap do |workflow|
              t1 = SetDescriptorsTask.create!({:name => 'Specify Dilution Volume', :sorted => 0, :workflow => workflow})
              Descriptor.create!({:kind => "Text", :sorter => 1, :name => "Concentration", :task => t1})
              t2 = SetDescriptorsTask.create!({:name => 'Cluster Generation', :sorted => 0, :workflow => workflow})
              Descriptor.create!({:kind => "Text", :sorter => 1, :name => "Chip barcode", :task => t2})
              Descriptor.create!({:kind => "Text", :sorter => 2, :name => "Cartridge barcode", :task => t2})
              Descriptor.create!({:kind => "Text", :sorter => 3, :name => "Operator", :task => t2})
              Descriptor.create!({:kind => "Text", :sorter => 4, :name => "Machine name", :task => t2})
          

					end
				end.tap do |pipeline|
					create_request_information_types(pipeline, 'fragment_size_required_from', 'fragment_size_required_to', 'library_type')
				end

     say "Submission template"
     ## Submission template
     miseq_sequencing = RequestType.find_by_key('miseq_sequencing')
     RequestType.find_each(:conditions => { :name => ['Library creation', 'Multiplexed library creation'] }) do |library_creation_request_type|
      submission                   = LinearSubmission.new
      submission.request_type_ids  = [ library_creation_request_type.id, miseq_sequencing.id ]
      submission.info_differential = next_gen_sequencing.id
      submission.workflow          = next_gen_sequencing
      submission.request_options   = {}
      ## Add custom fields for MiSeq
      library_type = FieldInfo.new(:default_value => "Standard", :kind => "Selection", :display_name => "Library type", :selection=>["NlaIII gene expression", "Standard", "Long range", "Small RNA", "DpnII gene expression", "qPCR only", "High complexity and double size selected", "Illumina cDNA protocol", "Custom", "High complexity", "Double size selected", "No PCR", "Agilent Pulldown", "ChiP-seq"], :key => "library_type")
      fragment_from = FieldInfo.new(:default_value => "", :kind => "Text", :display_name => "Fragment size required (from)", :key => "fragment_size_required_from")
      fragment_to => FieldInfo.new(:default_value => "", :kind => "Text", :display_name => "Fragment size required (to)", :key => "fragment_size_required_to")
      read_length = FieldInfo.new(:kind => "Selection", :key => "read_length", :display_name => "Read length", :default_value => "50", :selection => ["25","50","130","150"])
 
      submission.set_input_field_infos([fragment_from, fragment_to, library_type, insert_size])

      SubmissionTemplate.new_from_submission("#{library_creation_request_type.name} - #{miseq_sequencing.name}", submission).save!
    end 


  end

  def self.down
  end
end
