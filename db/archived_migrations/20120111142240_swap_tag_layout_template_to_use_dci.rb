#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class SwapTagLayoutTemplateToUseDci < ActiveRecord::Migration
  def self.up
    alter_table :tag_layout_templates do
      rename_column :layout_class_name, :direction_algorithm, :string
      add_column :walking_algorithm, :string, :default => 'TagLayout::WalkWellsByPools'
    end
    alter_table :tag_layouts do
      rename_column :sti_type, :direction_algorithm, :string
      add_column :walking_algorithm, :string, :default => 'TagLayout::WalkWellsByPools'
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, "Because typing is not backwards compatible"
  end
end
