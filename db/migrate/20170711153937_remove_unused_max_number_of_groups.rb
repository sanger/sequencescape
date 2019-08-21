# Rails migration
class RemoveUnusedMaxNumberOfGroups < ActiveRecord::Migration[4.2]
  def change
    remove_column :pipelines, :max_number_of_groups, :integer
  end
end
