# frozen_string_literal: true

class RenameColumnSampleConsentWithdrawn < ActiveRecord::Migration[5.2]
  def change
    rename_column :samples, :consent_withdrawn, :migrated_consent_withdrawn_to_metadata
  end
end
