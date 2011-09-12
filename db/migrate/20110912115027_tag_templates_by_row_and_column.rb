class TagTemplatesByRowAndColumn < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      # Update the existing tag layout templates to be column major order
      TagLayoutTemplate.find_each do |template|
        template.update_attributes!(
          :name              => "#{template.name} in column major order",
          :layout_class_name => 'TagLayout::InColumns'
        )
      end

      # Create the tag layouts for row major order
      TagGroup.find_each do |tag_group|
        TagLayoutTemplate.create!(
          :name              => "#{tag_group.name} in row major order",
          :tag_group         => tag_group,
          :layout_class_name => 'TagLayout::InRows'
        )
      end
    end
  end

  def self.down
    # There isn't much point in doing anything here really
  end
end
