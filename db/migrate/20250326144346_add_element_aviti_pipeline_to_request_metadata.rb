# frozen_string_literal: true
class AddElementAvitiPipelineToRequestMetadata < ActiveRecord::Migration[7.0]
  def change
    add_column :request_metadata, :low_diversity, :boolean
    add_column :request_metadata, :percent_phix_requested, :integer
  end
end
