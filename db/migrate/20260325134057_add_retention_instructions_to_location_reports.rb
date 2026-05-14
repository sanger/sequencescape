# frozen_string_literal: true
class AddRetentionInstructionsToLocationReports < ActiveRecord::Migration[7.2]
  def change
    add_column :location_reports, :retention_instructions, :string
  end
end
