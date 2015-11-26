#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class SwitchIlluminaBPlatesToVerticalCherrypick < ActiveRecord::Migration
  class PlatePurpose < ActiveRecord::Base
    self.table_name =('plate_purposes')
    set_inheritance_column
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
