class AddIlluminaBVerticalTaggingTemplate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      tag_group = TagGroup.find_by_name('Sanger_168tags - 10 mer tags') or raise "Cannot find requested tag group"

      TagLayoutTemplate.create!(
        :name => 'Illumina B vertical tagging',
        :direction_algorithm => 'TagLayout::InColumns',
        :walking_algorithm => 'TagLayout::WalkWellsOfPlate',
        :tag_group => tag_group
      )
    end
  end

  def self.down
    TagLayoutTemplate.find_by_name('Illumina B vertical tagging').destroy
  end
end
