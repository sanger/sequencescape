# frozen_string_literal: true

# Changes the datatype of the barcodes field to handle larger strings.
class ChangeLocationReportBarcodesDataType < ActiveRecord::Migration[5.1]
  def self.up
    change_column :location_reports, :barcodes, :text
  end

  def self.down
    # This might cause trouble if you have strings longer
    # than 255 characters.
    change_column :location_reports, :barcodes, :string
  end
end
