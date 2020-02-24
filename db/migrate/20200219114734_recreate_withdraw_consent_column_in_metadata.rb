# frozen_string_literal: true

# NB: 2020-Feb-21 The column consent_withdrawn was recovered in the Samples table. The procedure
# has been reviewed to perform the update. This migration changes the column to not allow nulls
class RecreateWithdrawConsentColumnInMetadata < ActiveRecord::Migration[5.2]
  def change
    remove_column :sample_metadata, :consent_withdrawn, :boolean
    add_column :sample_metadata, :consent_withdrawn, :boolean, null: false, default: false
  end
end
