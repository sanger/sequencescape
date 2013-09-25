class AddCherrypickForFluidgmPipeline < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do

      liw = LabInterface::Workflow.create!(:name=>'Cherrypick for Fluidgm')

      FluidgmTemplateTask.create!(
        :name => 'Select Plate Template',
        :pipeline_workflow_id => liw.id,
        :sorted => 1,
        :batched => true,
        :lab_activity => true
      )
      CherrypickTask.create!(
        :name => 'Approve Plate Layout',
        :pipeline_workflow_id => liw.id,
        :sorted => 2,
        :batched => true,
        :lab_activity => true
      )
      SetLocationTask.create!(
        :name => 'Set Location',
        :pipeline_workflow_id => liw.id,
        :sorted => 3,
        :batched => true,
        :lab_activity => true
      ) do |task|
        task.location_id = Location.find_by_name('Sample logistics freezer').id
      end


      CherrypickPipeline.create!(
        :name=>'Cherrypick for Fluidgm',
        :active => true,
        :location => Location.find_by_name('Sample logistics freezer'),
        :group_by_parent => true,
        :asset_type => 'Well',
        :sorter => 11,
        :paginate => false,
        :summary => true,
        :group_name => 'Sample Logistics',
        :workflow => liw,
        :request_types => RequestType.find_all_by_key(['pick_to_sta','pick_to_sta2','pick_to_fluidgm']),
        :control_request_type_id => 0,
        :max_size => 192
      ) do |pipeline|
      end

    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      CherrypickPipeline.find_by_name('Cherrypick for Fluidgm').destroy
      LabInterface::Workflow.find_by_name('Cherrypick for Fluidgm').tap do |liw|
        liw.tasks.each(&:destroy)
      end.destroy
    end
  end
end
