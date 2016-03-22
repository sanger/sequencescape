#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class ChangePulldownStockPlatePurpose < ActiveRecord::Migration
  class PlatePurpose < ActiveRecord::Base
    self.table_name =('plate_purposes')

    def self.change_implementation(to)
      PlatePurpose.update_all(
        "type=#{ to.nil? ? 'NULL' : to.inspect }",
        [ 'name IN (?)', [ 'WGS stock DNA', 'SC stock DNA', 'ISC stock DNA' ] ]
      )
    end
  end

  def self.up
    PlatePurpose.change_implementation('Pulldown::StockPlatePurpose')
  end

  def self.down
    PlatePurpose.change_implementation(nil)
  end
end
