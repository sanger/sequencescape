class RemoveUnusedMaxNumberOfGroups < ActiveRecord::Migration
  def change
    remove_column :pipelines, :max_number_of_groups, :integer
  end
end
