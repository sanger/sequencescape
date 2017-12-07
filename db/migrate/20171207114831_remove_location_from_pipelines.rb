class RemoveLocationFromPipelines < ActiveRecord::Migration[5.1]
  def change
    remove_column :pipelines, :location_id
  end
end
