# frozen_string_literal: true

# Move old withdraw consent setting into the new columns of sample metadata
class MoveWithdrawConsentToSampleMetadata < ActiveRecord::Migration[5.2]
  def up
    # The following commented content has been deprecated by following migrations 202002119114734,
    # 20200219114917 and 20200219115102
    #
    # ActiveRecord::Base.transaction do
    #   Sample.where(consent_withdrawn: true).each do |sample|
    #     sample.sample_metadata.update!(consent_withdrawn: sample.consent_withdrawn)
    #   end
    # end
  end
end
