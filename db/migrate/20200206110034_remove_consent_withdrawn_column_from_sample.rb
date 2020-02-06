class RemoveConsentWithdrawnColumnFromSample < ActiveRecord::Migration[5.2]
  def change
    remove_column :samples, :consent_withdrawn
  end
end
