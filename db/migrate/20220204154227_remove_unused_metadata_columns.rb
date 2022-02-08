# frozen_string_literal: true

# Remove unused long-read pipeline columns
class RemoveUnusedMetadataColumns < ActiveRecord::Migration[6.0]
  def change
    remove_column :sample_metadata, :saphyr, :string
    remove_column :sample_metadata, :pacbio, :string
  end
end
