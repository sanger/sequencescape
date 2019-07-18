# Rails migration
class AddPlatePurposesToQcReport < ActiveRecord::Migration
  def change
    add_column :qc_reports, :plate_purposes, :text
  end
end
