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
