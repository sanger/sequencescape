class RemovePlatePurposesPulldownDisplayColumn < ActiveRecord::Migration
  def change
    remove_column :plate_purposes, :pulldown_display, :boolean
  end
end
