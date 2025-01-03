# frozen_string_literal: true

# This migration renames the column number_of_samples_per_pool to
# number_of_pools in the request_metadata table for the scRNA cDNA Prep
# submissions. The column will be used for storing the number of pools
# requested for a study-project.
class RenameColumnNumberOfSamplesPerPoolToNumberOfPools < ActiveRecord::Migration[7.0]
  def change
    rename_column :request_metadata, :number_of_samples_per_pool, :number_of_pools
  end
end
