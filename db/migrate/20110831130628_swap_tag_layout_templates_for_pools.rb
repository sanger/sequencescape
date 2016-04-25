#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
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
