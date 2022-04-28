# frozen_string_literal: true

# Store information about location reports to allow them to be generated asynchronously
# and retrieved later
class AddLocationReportsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :location_reports do |t|
      t.references :user, null: false
      t.string :name, null: false, unique: true
      t.integer :report_type, null: false
      t.string :barcodes, null: true
      t.references :study, null: true
      t.string :plate_purpose_ids, null: true
      t.datetime :start_date, null: true
      t.datetime :end_date, null: true
      t.string :report_filename, null: true

      t.timestamps
    end
  end
end
