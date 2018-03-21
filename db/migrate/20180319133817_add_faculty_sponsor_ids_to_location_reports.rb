class AddFacultySponsorIdsToLocationReports < ActiveRecord::Migration[5.1]
  def change
    add_column :location_reports, :faculty_sponsor_ids, :string, null: true, :after => :barcodes
  end
end
