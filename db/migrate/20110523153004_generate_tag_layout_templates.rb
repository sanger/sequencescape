class GenerateTagLayoutTemplates < ActiveRecord::Migration
  def self.each_tag_group(&block)
    ActiveRecord::Base.transaction do
      TagGroup.find_each do |tag_group|
        yield({
          :name              => "#{tag_group.name} in column major order",
          :tag_group         => tag_group,
          :layout_class_name => 'TagLayout::InColumns'
        })
        yield({
          :name              => "#{tag_group.name} in row major order",
          :tag_group         => tag_group,
          :layout_class_name => 'TagLayout::InRows'
        })
      end
    end
  end
  def self.up
    each_tag_group(&TagLayoutTemplate.method(:create!))
  end

  def self.down
    each_tag_group do |conditions|
      TagGroup.destroy_all([ 'name=?', conditions[:name] ])
    end
  end
end
