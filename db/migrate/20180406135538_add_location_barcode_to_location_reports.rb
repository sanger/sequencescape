# frozen_string_literal: true

# Adding a column to hold labwhere location barcode to the location reports table
class AddLocationBarcodeToLocationReports < ActiveRecord::Migration[5.1]
  def change
    add_column :location_reports, :location_barcode, :string, null: true, after: :report_type
  end
end
