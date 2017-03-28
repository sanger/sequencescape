class RemovePlatePurposesQcDisplayColumn < ActiveRecord::Migration
  def change
    remove_column :plate_purposes, :qc_display, :boolean, default: false
  end
end
