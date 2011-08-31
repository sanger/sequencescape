class SwapTagLayoutTemplatesForPools < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      TagLayoutTemplate.find_each do |template|
        template.update_attributes!(
          :layout_class_name => 'TagLayout::ByPools',
          :name              => template.name.sub(/ in column major order$/, '')
        )
      end
    end
  end

  def self.down
    # No point really worrying about the name I guess
    TagLayoutTemplate.update_all('layout_class_name="TagLayout::InColumns"')
  end
end
