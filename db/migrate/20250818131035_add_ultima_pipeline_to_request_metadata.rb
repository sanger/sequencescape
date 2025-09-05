# frozen_string_literal: true
class AddUltimaPipelineToRequestMetadata < ActiveRecord::Migration[7.1]
  def change
    add_column :request_metadata, :ot_recipe, :integer
  end
end
