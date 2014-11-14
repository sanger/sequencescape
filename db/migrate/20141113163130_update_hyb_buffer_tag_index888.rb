class UpdateHybBufferTagIndex888 < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      tag_group = TagGroup.create!(:name => "Control Tag Group - Sanger_168tags - 10 mer tags")
      template = TagLayoutTemplate.create!(
        :direction_algorithm => "TagLayout::InColumns",
        :tag_group => tag_group,
        :name => "Control Tag - Sanger_168tags - 10 mer tags",
        :walking_algorithm => "TagLayout::WalkWellsByPools")
      copied_tag_group = TagGroup.find_by_name("Sanger_168tags - 10 mer tags")
      copied_tag_group.tags.each do |tag|
        tag_group.tags.create!(:map_id => tag.map_id + 887, :oligo => tag.oligo)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      t = TagGroup.find_by_name("Control Tag Group - Sanger_168tags - 10 mer tags")
      t.tags.each do |tag|
        tag.destroy
      end
      TagLayoutTemplate.find_by_name("Control Tag - Sanger_168tags - 10 mer tags").destroy
      t.destroy
    end
  end
end
