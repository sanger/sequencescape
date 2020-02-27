# frozen_string_literal: true

# Remove old consent withdrawn column from samples
class RemoveConsentWithdrawnColumnFromSample < ActiveRecord::Migration[5.2]
  def up
    # The following commented content has been deprecated by following migrations 202002119114734,
    # 20200219114917 and 20200219115102:
    #
    # remove_column :samples, :consent_withdrawn
  end
end
