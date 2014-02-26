class AddPacbioCherrypickPipeline < ActiveRecord::Migration
  require 'control_request_type_creation'

  def self.up
    Pipeline.send(:include, ControlRequestTypeCreation)

    ActiveRecord::Base.transaction do

      liw = LabInterface::Workflow.create!(:name=>'PacBio Cherrypick')

      LabInterface::Workflow.find_by_name('Cherrypick').tasks.each do |task|
        # next if task.name == 'Set Location'
        new_task = task.clone
        new_task.workflow = liw
        new_task.save!
      end

      CherrypickPipeline.create!(
        :name => 'PacBio Cherrypick',
        :active => true,
        :automated=>false,
        :location_id => Location.find_by_name('PacBio library prep freezer'),
        :group_by_parent => true,
        :asset_type => 'Well',
        :group_name => 'R&D',
        :max_size => 3000,
        :sorter=>10,
        :request_types => [RequestType.find_by_key!('pacbio_cherrypick')],
        :workflow => liw
      ) do |pipeline|
        pipeline.add_control_request_type
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      CherrypickPipeline.find_by_name('PacBio Cherrypick').destroy
      LabInterface::Workflow.find_by_name('PacBio Cherrypick').destroy
      RequestType.find_by_key('pacbio_cherrypick_control').destroy
    end
  end
end
