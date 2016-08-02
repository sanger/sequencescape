#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddSharedTagTemplate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      TagLayoutTemplate.create!(
        :name => 'Illumina pipeline tagging',
        :walking_algorithm => 'TagLayout::WalkWellsOfPlate',
        :tag_group => TagGroup.find_by_name('Sanger_168tags - 10 mer tags'),
        :direction_algorithm => 'TagLayout::InColumns'
        )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      TagLayoutTemplate.find_by_name('Illumina pipeline tagging').destroy
    end
  end
end
