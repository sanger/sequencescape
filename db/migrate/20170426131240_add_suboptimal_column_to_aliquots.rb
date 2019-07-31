# Rails migration
class AddSuboptimalColumnToAliquots < ActiveRecord::Migration
  def change
    add_column :aliquots, :suboptimal, :boolean, default: false, null: false
  end
end
