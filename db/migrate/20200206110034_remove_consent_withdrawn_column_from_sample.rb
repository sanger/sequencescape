# frozen_string_literal: true

# Remove old consent withdrawn column from samples
class RemoveConsentWithdrawnColumnFromSample < ActiveRecord::Migration[5.2]
  def up
    remove_column :samples, :consent_withdrawn
  end
end
