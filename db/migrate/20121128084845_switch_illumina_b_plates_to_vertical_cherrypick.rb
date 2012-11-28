class SwitchIlluminaBPlatesToVerticalCherrypick < ActiveRecord::Migration
  class PlatePurpose < ActiveRecord::Base
    set_table_name('plate_purposes')
    set_inheritance_column(nil)
  end

  def self.up
    change('column')
  end

  def self.down
    change('row')
  end

  def self.change(direction)
    ActiveRecord::Base.transaction do
      PlatePurpose.find_by_name('ILB_STD_INPUT').update_attributes!(:cherrypick_direction => direction)
    end
  end
end
