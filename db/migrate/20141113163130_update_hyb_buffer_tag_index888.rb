class UpdateHybBufferTagIndex888 < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      tag_group = TagGroup.create!(:name => "Control Tag Group 888")
      template = TagLayoutTemplate.create!(
        :direction_algorithm => "TagLayout::InColumns",
        :tag_group => tag_group,
        :name => "Control Tag 888",
        :walking_algorithm => "TagLayout::WalkWellsByPools")
      copied_tag = TagGroup.find_by_name("Sanger_168tags - 10 mer tags").tags.select {|t| t.map_id==1}.first
      tag_group.tags.create!(:map_id => 888, :oligo => copied_tag.oligo)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      t = TagGroup.find_by_name("Control Tag Group 888")
      t.tags.each do |tag|
        tag.destroy
      end
      TagLayoutTemplate.find_by_name("Control Tag 888").destroy
      t.destroy
    end
  end
end
