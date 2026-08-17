# frozen_string_literal: true
# This migration adds the Ultima application_type column to request_metadata.
class AddApplicationTypeToRequestMetadata < ActiveRecord::Migration[8.0]
  def change
    add_column :request_metadata,
               :application_type,
               :string,
               comment: 'Ultima application type (e.g., converted-truseq)'
  end
end
