class AddFieldsToReceptacles < ActiveRecord::Migration[5.2]
  def change
    add_column :receptacles, :pcr_cycles, :integer
    add_column :receptacles, :submit_for_sequencing, :boolean
    add_column :receptacles, :sub_pool, :integer
    add_column :receptacles, :coverage, :integer
  end
end
