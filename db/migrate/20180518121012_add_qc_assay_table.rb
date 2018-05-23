# frozen_string_literal: true

# Add a qc_assay table to allow us to group together qc results
class AddQcAssayTable < ActiveRecord::Migration[5.1]
  def change
    create_table :qc_assays, &:timestamps
  end
end
