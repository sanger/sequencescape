class AddX10Pipelines < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      ['(spiked in controls)','(no controls)'].each do |type|
        SequencingPipeline.create!(
          :name => "HiSeq X Ten PE #{type}",
            :automated => false,
            :active => true,
            :location => Location.find_by_name("Cluster formation freezer"),
            :group_by_parent => false,
            :asset_type => "Lane",
            :sorter => 9,
            :paginate => false,
            :max_size => 8,
            :min_size => 1,
            :summary => true,
            :group_name => "Sequencing",
            :control_request_type_id => 0
          ) do |pipeline|
            pipeline.workflow = clone_workflow(type)
            pipeline.request_types = ["a", "b"].map {|pipelinetype| RequestType.find_by_key("illumina_#{pipelinetype}_hiseq_xten_paired_end_sequencing")}
          end
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ['(spiked in controls)','(no controls)'].each do |type|
        pipeline = SequencingPipeline.find_by_name("HiSeq X Ten PE #{type}")
        unless pipeline.nil?
          pipeline.workflow.tasks.each {|t| t.descriptors.each(&:destroy); t.destroy }
          unless pipeline.workflow.nil?
            pipeline.workflow.destroy
          end
          pipeline.destroy
        end
      end
    end
  end
  
  def self.clone_workflow(type)
    wf = LabInterface::Workflow.find_by_name("Cluster formation PE HiSeq (no control)#{type=='(spiked in controls)'? ' '+type : '' }") ||
        LabInterface::Workflow.find_by_name("HiSeq Cluster formation PE #{type}")
        
    wf.deep_copy("_suf", true).tap do |val| 
      val.tasks = val.tasks.select {|task| task.name.match(/Quality control/).nil? } 
      val.name="HiSeq X Ten PE #{type}" 
      val.save!
    end
  end
end
