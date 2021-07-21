# frozen_string_literal: true

# We don't use any of these attributes actively any more, flow is mostly
# determined by the request graph, and automated only applied to a single
# now disabled pipeline
class RemoveUnusedColumnsFromPipeline < ActiveRecord::Migration[5.2]
  def change
    remove_column :pipelines, :next_pipeline_id, :integer
    remove_column :pipelines, :previous_pipeline_id, :integer
    remove_column :pipelines, :automated, :boolean
  end
end
