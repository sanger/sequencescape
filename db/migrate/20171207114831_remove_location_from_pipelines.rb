# frozen_string_literal: true

class RemoveLocationFromPipelines < ActiveRecord::Migration[5.1]
  def change
    remove_column :pipelines, :location_id, :integer
  end
end
