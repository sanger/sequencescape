# frozen_string_literal: true
class AddAllowanceBandsToRequestMetadata < ActiveRecord::Migration[7.0]
  def change
    add_column :request_metadata, :allowance_band, :string
  end
end
