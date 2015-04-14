#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class RemoveSmrtCellsTasks < ActiveRecord::Migration

  class SmrtCellsTask < Task; end

  def self.up
    ActiveRecord::Base.transaction do
      Pipeline.find_by_name!('PacBio Library Prep').workflow.tasks.find_by_name('Number of SMRTcells that can be made').destroy
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
