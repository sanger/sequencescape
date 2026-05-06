# frozen_string_literal: true
class AddPlateBarcodesToQcReports < ActiveRecord::Migration[8.0]
  def change
    add_column :qc_reports, :plate_barcodes, :text, size: :medium
  end
end
