# frozen_string_literal: true
class AddPlateBarcodesToQcReports < ActiveRecord::Migration[8.0]
  def change
    add_column :qc_reports, :plate_barcodes, :text, size: :medium

    # Allow null values for study_id to allow qc_reports to be create without a study (just plate_barcodes)
    change_column_null :qc_reports, :study_id, true
  end
end
