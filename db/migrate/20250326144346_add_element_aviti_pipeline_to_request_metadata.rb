class AddElementAvitiPipelineToRequestMetadata < ActiveRecord::Migration[7.0]
  def change
    add_column :request_metadata, :low_diversity, :boolean
    add_column :request_metadata, :percent_element_phix_needed, :integer
  end
end
