class RemoveQcStageFrom2500 < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      affected_pipeline_workflows.each do |workflow|
        Task.find(:first, :conditions => {
          :name => 'Quality control',
          :pipeline_workflow_id => workflow.id
          }).destroy
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      affected_pipeline_workflows.each do |workflow|
        SetDescriptorsTask.create!(
          :name => 'Quality control',
          :pipeline_workflow_id => workflow.id,
          :sorted => 4,
          :interactive => false,
          :per_item => false,
          :batched => true
          ).tap do |task|
            Descriptor.create!(:name => "Chip Barcode", :selection => {"1"=>""},
                               :task => task, :kind => "Text", :required => false,:sorter => 1,:key => "")
            Descriptor.create!(:name => "Operator",     :selection => {"1"=>"Yes","2"=>"No","3"=>"Not selected"},
                               :task => task, :kind => "Text", :required => false,:sorter => 2,:key => "")
            Descriptor.create!(:name => "Passed?",      :selection => {"1"=>"Yes","2"=>"No","3"=>"Not processed"},
                               :task => task, :kind => "Selection",:required => false,:sorter => 3,:key => "")
            Descriptor.create!(:name => "Comment",      :selection => {"1"=>""},
                               :task => task, :kind => "Text", :required => false,:sorter => 4,:key => "")
        end
      end
    end
  end

  def self.affected_pipeline_workflows
    [
      Pipeline.find_by_name('HiSeq 2500 PE (spiked in controls)').workflow,
      Pipeline.find_by_name('HiSeq 2500 SE (spiked in controls)').workflow
    ]
  end
end
