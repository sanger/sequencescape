class AddWithdrawConsentToSampleMetadata < ActiveRecord::Migration[5.2]
  def change
    add_column :sample_metadata, :consent_withdrawn, :boolean, default: false
    add_column :sample_metadata, :date_of_consent_withdrawn, :datetime
    add_column :sample_metadata, :user_id_of_consent_withdrawn, :integer
  end
end
