class AddV4Pipelines < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      ['(spiked in controls)','(no controls)'].each do |type|
        SequencingPipeline.create!(
          :name => "HiSeq 2500 v4 PE #{type}",
            :automated => false,
            :active => true,
            :location => Location.find_by_name("Cluster formation freezer"),
            :group_by_parent => false,
            :asset_type => "Lane",
            :sorter => 9,
            :paginate => false,
            :max_size => 8,
            :min_size => 8,
            :summary => true,
            :group_name => "Sequencing",
            :control_request_type_id => 0
          ) do |pipeline|
            pipeline.workflow = clone_workflow(type)
            pipeline.request_types = ["a", "b", "c"].map {|pipelinetype| RequestType.find_by_key("illumina_#{pipelinetype}_hiseq_2500_v4_paired_end_sequencing")}
          end
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ['(spiked in controls)','(no controls)'].each do |type|      
        SequencingPipeline.find_by_name("HiSeq 2500 v4 PE #{type}").tap do |pipeline|
          pipeline.workflow.tasks.each {|t| t.descriptors.each(&:destroy); t.destroy }
          pipeline.workflow.destroy
        end.destroy
      end
    end
  end
  
  def self.clone_workflow(type)
    wf = LabInterface::Workflow.find_by_name("Cluster formation PE HiSeq (no control)#{type=='(spiked in controls)'? ' '+type : '' }") ||
        LabInterface::Workflow.find_by_name("HiSeq Cluster formation PE #{type}")
        
    wf.deep_copy("_suf", true).tap {|val| val.name="HiSeq 2500 v4 PE #{type}" ; val.save! }
  end
end
