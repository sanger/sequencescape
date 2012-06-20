class AddIlluminaBTagLayoutTemplate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      tag_group = TagGroup.find_by_name('Sanger_168tags - 10 mer tags') or raise "Cannot find requested tag group"

      TagLayoutTemplate.create!(
        :name => 'Illumina B tagging',
        :direction_algorithm => 'TagLayout::InRows',
        :walking_algorithm => 'TagLayout::WalkWellsOfPlate',
        :tag_group => tag_group
      )
    end
  end

  def self.down
    TagLayoutTemplate.find_by_name('Illumina B tagging').destroy
  end
end
