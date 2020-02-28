# frozen_string_literal: true

#
# Remove the column migrated_consent_withdrawn_to_metadata from the Samples table because
# it is no longer needed
class RemoveColumnMigratedConsentWithdrawnFromSamples < ActiveRecord::Migration[5.2]
  def change
    remove_column :samples, :migrated_consent_withdrawn_to_metadata, :boolean, default: false, null: false
  end
end
