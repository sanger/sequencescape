class RemoveSmrtCellsTasks < ActiveRecord::Migration

  class SmrtCellsTask < Task; end

  def self.up
    ActiveRecord::Base.transaction do
      # Pipeline.find_by_name!('PacBio Library Prep').workflow.tasks.find_by_name('Number of SMRTcells that can be made').destroy
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Pipeline.find_by_name!('PacBio Library Prep').workflow.tasks << SmrtCellsTask.create!(
        :name=>'Number of SMRTcells that can be made',
        :sorted=>3,
        :batched=>true,
        :lab_activity=>true)
    end
  end

end
