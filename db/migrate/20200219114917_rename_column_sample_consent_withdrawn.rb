# frozen_string_literal: true

# NB: 2020-Feb-21 The column consent_withdrawn was recovered in the Samples table. The procedure
# has been reviewed to perform the update. This migration renames current consent_withdrawn column
class RenameColumnSampleConsentWithdrawn < ActiveRecord::Migration[5.2]
  def change
    rename_column :samples, :consent_withdrawn, :migrated_consent_withdrawn_to_metadata
  end
end
