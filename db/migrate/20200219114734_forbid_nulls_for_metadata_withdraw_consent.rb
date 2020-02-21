# frozen_string_literal: true

class ForbidNullsForMetadataWithdrawConsent < ActiveRecord::Migration[5.2]
  def change
    change_column :sample_metadata, :consent_withdrawn, :boolean, null: false
  end
end
