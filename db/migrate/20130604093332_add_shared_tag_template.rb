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
