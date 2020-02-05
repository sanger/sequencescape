class MoveWithdrawConsentToSampleMetadata < ActiveRecord::Migration[5.2]
  def up
    ActiveRecord::Base.transaction do
      Sample.where(consent_withdrawn: true).each do |sample|
        sample.sample_metadata.update_attributes!(consent_withdrawn: sample.consent_withdrawn)
      end
    end
  end
end
