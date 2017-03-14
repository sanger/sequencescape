class PlatePurposeTargetTypeIsRequired < ActiveRecord::Migration
  def change
    change_column_null :plate_purposes, :target_type, true
  end
end
