# frozen_string_literal: true
class RemoveColumnFromSampleMetadata < ActiveRecord::Migration[7.0]
  def change
    remove_column :sample_metadata, :huMFre_code, :string
  end
end
